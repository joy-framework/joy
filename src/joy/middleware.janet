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


(defn- safe-unmarshal [val]
  (unless (or (nil? val) (empty? val))
    (unmarshal val)))


(defn- decrypt-session [key str]
  (when (string? str)
    (try
      (cipher/decrypt key str)
      ([err]
       (unless (= err "decryption failed")
         (error err))))))


(defn- decode-session [str key]
  (when (and (string? str)
             (truthy? key))
    (as-> str ?
          (decrypt-session key ?)
          (safe-unmarshal ?))))


(defn- encode-session [val key]
  (when (truthy? key)
    (->> (marshal val)
         (string)
         (cipher/encrypt key))))


(defn- session-from-request [key request]
  (as-> (get-in request [:headers "Cookie"]) ?
        (http/parse-cookie ?)
        (get ? "id")
        (decode-session ? key)))


(defn session [handler]
  (let [key (env/env :encryption-key)]
    (fn [request]
      (let [request-session (or (session-from-request key request)
                                @{})
            response (handler (merge request request-session))
            session-value (or (get response :session)
                              (get request-session :session))]
          (let [joy-session {:session session-value :csrf-token (get response :csrf-token)}]
            (when (truthy? response)
              (put-in response [:headers "Set-Cookie"]
                (http/cookie-string "id" (encode-session joy-session key)
                  {"SameSite" "Strict" "HttpOnly" "" "Path" "/"}))))))))


(defn xor-byte-strings [str1 str2]
  (let [arr @[]
        bytes1 (string/bytes str1)
        bytes2 (string/bytes str2)]
    (loop [i :range [0 32]]
      (array/push arr (bxor (get bytes1 i) (get bytes2 i))))
    (string/from-bytes ;arr)))


(defn mask-token [request]
  (let [pad (os/cryptorand 32)
        csrf-token (get request :csrf-token)
        masked-token (xor-byte-strings pad csrf-token)]
    (base64/encode (string pad masked-token))))


(defn session-csrf-token [request]
  (or (get request :csrf-token)
      (os/cryptorand 32)))


(defn form-csrf-token [request]
  (mask-token request))


(defn csrf-tokens-equal? [form-token session-token]
  (cipher/secure-compare form-token session-token))


(defn multipart-csrf-token [request]
  (as-> request ?
        (get ? :multipart-body)
        (filter |(= (get $ :name) "__csrf-token") ?)
        (first ?)
        (get ? :content)))


(defn unmask-token [request]
  (let [masked-token (or (get-in request [:body :__csrf-token])
                         (multipart-csrf-token request))
        _ (when (nil? masked-token)
            (error "Required parameter __csrf-token not found"))
        token (base64/decode masked-token)
        pad (string/slice token 0 32)
        csrf-token (string/slice token 32)]
    (xor-byte-strings pad csrf-token)))


(defn csrf-token [handler]
  (fn [request]
    (let [session-token (session-csrf-token request)]
       (if (or (head? request) (get? request))
         (when-let [response (handler request)]
           (put response :csrf-token session-token))
         (let [form-token (unmask-token request)]
           (if (csrf-tokens-equal? form-token session-token)
             (when-let [response (handler request)]
               (put response :csrf-token session-token))
             (-> (responder/render :text "Invalid CSRF Token" :status 403)
                 (put :csrf-token session-token))))))))


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
      (if (and body
               (post? request)
               (not (http/multipart? request)))
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
    (try
      (handler request)
      ([err fib]
       (debug/stacktrace fib err)
       (if env/development?
         (responder/respond :html
           (dev-error-page request err)
           :status 500)
         @{:status 500
           :body "Internal Server Error"
           :headers @{"Content-Type" "text/plain"}})))))


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
          request (merge request {:query-string query-string})]
      (handler request))))


(defn file-uploads
  `This middleware attempts parse multipart form bodies
   and saves temp files for each part with a filename
   content disposition

   The tempfiles are deleted after your handler is called

   It then returns the body as an array of dictionaries like this:

   @[{:filename "name of file" :content-type "content-type" :size 123 :tempfile "<file descriptor>"}]`
  [handler]
  (fn [request]
    (if (and (get request :body)
             (post? request)
             (http/multipart? request))
      (let [body (http/parse-multipart-body request)
            response (handler (put request :multipart-body body))
            files (as-> body ?
                        (map |(get $ :temp-file) ?)
                        (filter truthy? ?))]
        (loop [f :in files] # delete temp files
          (file/close f))
        response)
      (handler request))))


(defn route [{:method method :uri uri}]
  [method uri])


(defn auth [handler &opt options]
  (default options {:email {:table "users"
                            :sign-in {:uri "/sign-in" :get sessions/new :post sessions/create}
                            :sign-up {:uri "/sign-up" :get users/new :post users/create}
                            :sign-out {:delete sessions/destroy}}
                    :magic-link {:table "users"
                                 :sign-in {:uri "/sign-in" :get sessions/new :post sessions/create}
                                 :sign-out {:delete sessions/destroy}}})
  (let [sign-in (get-in options [:sign-in :uri])
        sign-up (get-in options [:sign-up :uri])
        new-session (get-in options [:sign-in :get])
        create-session (get-in options [:sign-in :post])
        new-user (get-in options [:sign-up :get])
        create-user (get-in options [:sign-up :post])
        delete-session (get-in options [:sign-out :delete])]
    (fn [request]
      (match (route request)
        ["GET" sign-up]              (new-user  request)
        ["POST" (string "/" table)]  (create-user request)

        ["GET" sign-in]              (new-session request)
        ["POST" "/sessions"]         (create-session request)

        ["GET" "/forgot-password"]   (forgot-password request)
        ["PATCH" (string "/" table)] (patch-user request)

        ["DELETE" "/sessions"]       (delete-session request)

        (handler request)))))
