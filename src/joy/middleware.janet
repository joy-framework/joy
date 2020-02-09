(import ./helper :prefix "")
(import ./http :as http)
(import ./logger :as logger)
(import ./env :as env)
(import ./db1 :as db)
(import ./responder :as responder)
(import ./html :as html)
(import ./router :as router)
(import ./base64 :as base64)
(import cipher)
(import path)


(defn layout [handler layout-fn]
  (fn [request]
    (let [response (handler request)
          response (if (indexed? response) @{:status 200 :body response :request request} response)]
      (if (= 200 (get response :status))
        (layout-fn response)
        response))))


(defn db [handler db-name]
  (let [schema (db/with-db-connection [conn db-name]
                 (->> (db/query conn `select sqlite_master.name as tbl,
                                             pti.name as col
                                      from sqlite_master
                                      join pragma_table_info(sqlite_master.name) pti on sqlite_master.name != pti.name
                                      order by pti.cid`)
                      (filter |(= "updated_at" (get $ :col)))
                      (map |(struct (get $ :tbl) (get $ :col)))
                      (apply merge)))]
    (fn [request]
      (db/with-db-connection [conn db-name]
        (handler (put request :db {:schema schema :connection conn}))))))


(defn static-files [handler &opt root]
  (default root "./public")
  (fn [request]
    (let [{:method method :uri uri} request
          filename (path/join root uri)]
      (if (and (some (partial = method) ["GET" "HEAD"])
            (path/ext filename)
            (file-exists? filename))
        {:file filename}
        (handler request)))))


(defn set-cookie [handler cookie-name cookie-value &opt options]
  (default options {"SameSite" "Strict"
                    "HttpOnly" ""
                    "Path" "/"})
  (default cookie-name "id")
  (default cookie-value "value")
  (fn [request]
    (let [response (handler request)]
      (put-in response
        [:headers "Set-Cookie"]
        (http/cookie-string cookie-name cookie-value options)))))


(defn- decode-session [str encryption-key]
  (when (truthy? str)
    (let [decrypted (->> (base64/decode str)
                         (cipher/decrypt encryption-key))]
      (when (and (not (nil? decrypted))
                 (not (empty? decrypted)))
        (unmarshal decrypted)))))


(defn- encode-session [val encryption-key]
  (when (truthy? encryption-key)
    (->> (marshal val)
         (string)
         (cipher/encrypt encryption-key)
         (base64/encode))))


(defn session [handler]
  (let [encryption-key (base64/decode (env/env :encryption-key))]
    (fn [request]
      (let [decoded-session (try
                              (-> (get-in request [:headers "Cookie"])
                                  (http/parse-cookie)
                                  (get "id")
                                  (decode-session encryption-key))
                              ([err]
                               (logger/log {:msg err :attrs [:action "decode-session" :uri (get request :uri) :method (get request :method)] :level "error"})))
            response (handler (merge request (or decoded-session {})))
            session-value (or (get response :session)
                              (get decoded-session :session))
            session-id (or (get decoded-session :session-id)
                           (base64/encode (cipher/password-key)))]
          (let [joy-session {:session session-value :session-id session-id :csrf-token (get response :csrf-token)}]
            (when (truthy? response)
              (put-in response [:headers "Set-Cookie"]
                (http/cookie-string "id" (encode-session joy-session encryption-key)
                  {"SameSite" "Strict" "HttpOnly" "" "Path" "/"}))))))))


(defn session-id [request]
  (when-let [id (get request :session-id)]
    (base64/decode id)))


(defn decode-token [token session-id]
  (when (truthy? token)
    (->> (base64/decode token)
         (cipher/decrypt session-id))))


(defn form-csrf-token [request]
  (decode-token (get-in request [:body :csrf-token])
                (session-id request)))


(defn session-token [request]
  (decode-token (get request :csrf-token)
                (session-id request)))


(defn new-csrf-token [session-id]
  (when (truthy? session-id)
    (->> (rand-str 20) (cipher/encrypt session-id) (base64/encode))))


(defn csrf-token [handler]
  (fn [request]
    (let [session-id (session-id request)
          new-csrf-token (new-csrf-token session-id)]
       (if (or (head? request) (get? request))
         (let [response (handler (put request :csrf-token new-csrf-token))]
           (when (truthy? response)
             (put response :csrf-token new-csrf-token)))
         (let [session-token (session-token request)
               form-csrf-token (form-csrf-token request)]
           (if (= form-csrf-token session-token)
             (let [response (handler request)]
               (when (truthy? response)
                 (put response :csrf-token new-csrf-token)))
             (responder/render :text "Invalid CSRF Token" :status 403)))))))


(defn x-headers [handler &opt options]
  (default options @{"X-Frame-Options" "SAMEORIGIN"
                     "X-XSS-Protection" "1; mode=block"
                     "X-Content-Type-Options" "nosniff"
                     "X-Download-Options" "noopen"
                     "X-Permitted-Cross-Domain-Policies" "none"
                     "Referrer-Policy" "strict-origin-when-cross-origin"})
  (fn [request]
    (let [response (handler request)]
      (when response
        (update response :headers merge options)))))


(defn body-parser [handler]
  (fn [request]
    (let [{:body body} request]
      (if (and body (post? request))
        (handler (merge request {:body (http/parse-body body)}))
        (handler request)))))


(defn- dev-error-page [request err]
  (html/html
    (html/doctype :html5)
    [:html {:lang "en"}
     [:head
      [:meta {:charset "utf-8"}]
      [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
      [:title (string "Error at " (get request :uri))]]
     [:body {:style "margin: 0; font-family: sans-serif;"}
      [:div {:style "background-color: #FF4136; padding: 20px"}
       [:strong {:style "color: hsla(3, 100%, 25%, 1.0)"} (string "Error at " (get request :uri))]
       [:div {:style "color: hsla(3, 100%, 25%, 1.0)"} err]]
      [:div {:style "padding: 20px"}
       [:strong "Request Information"]
       [:pre
        [:code
         (string/format "%p" request)]]]]]))


(defn server-error [handler]
  (fn [request]
    (let [f (fiber/new (partial handler request) :eip)
          res (resume f)]
      (if (not= (fiber/status f) :error)
        res
        (do
          (let [attrs (kvs (select-keys request [:body :params]))]
            (logger/log {:msg res :attrs attrs :level "error"}))
          (debug/stacktrace f res)
          (if (= "development" (env/env :joy-env))
            (responder/respond :html
              (dev-error-page request res)
              :status 500)
            @{:status 500
              :body "Internal Server Error"
              :headers @{"Content-Type" "text/plain"}}))))))


(defn not-found [handler &opt custom-fn]
  (fn [request]
    (let [response (handler request)]
      (if (dictionary? response)
        response
        (if (function? custom-fn)
          (custom-fn request)
          (responder/respond :text "not found" :status 404))))))


(defn extra-methods [handler]
  (fn [request]
    (let [{:method method :body body} request
          body (if (dictionary? body) body @{})
          extra-method (get body :_method method)]
      (handler
       (merge request {:method extra-method
                       :original-method method})))))


(defn query-string [handler]
  (fn [request]
    (let [{:uri uri} request
          query-string (http/parse-query-string uri)
          request (put request :query-string query-string)]
      (handler request))))
