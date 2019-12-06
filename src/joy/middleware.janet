(import ./helper :as helper)
(import ./http :as http)
(import ./logger :as logger)
(import ./env :as env)
(import ./db :as db)
(import ./responder :as responder)
(import ./html :as html)
(import cipher)
(import json)
(import codec)
(import path)


(defn set-layout [handler layout]
  (fn [request]
    (let [response (handler request)
          response (if (indexed? response) @{:status 200 :body response} response)]
      (if (= 200 (get response :status))
        (layout response)
        response))))


(defn set-db [handler conn]
  (fn [request]
    (db/with-db-connection [db conn]
      (handler (put request :db db)))))


(defn static-files [handler &opt root]
  (default root "./public")
  (fn [request]
    (let [{:method method :uri uri} request
          filename (path/join root uri)]
      (if (and (some (partial = method) ["GET" "HEAD"])
            (helper/file-exists? filename)
            (not (nil? (path/ext filename))))
        {:file filename}
        (handler request)))))


(defn set-cookie [handler &opt cookie-name cookie-value options]
  (default options {"SameSite" "Strict"
                    "HttpOnly" ""})
  (default cookie-name "id")
  (default cookie-value "id")
  (fn [request]
    (let [response (handler request)]
      (put-in response
        [:headers "Set-Cookie"]
        (http/cookie-string cookie-name cookie-value options)))))


(defn- decode-session [str encryption-key]
  (when (not (nil? str))
    (let [decrypted (->> (codec/decode str)
                         (cipher/decrypt encryption-key))]
      (when (not (nil? decrypted))
        (json/decode decrypted)))))


(defn- encode-session [val encryption-key]
  (when (not (nil? val))
    (->> (json/encode val)
         (string)
         (cipher/encrypt encryption-key)
         (codec/encode))))


(defn session [handler]
  (let [encryption-key (codec/decode
                        (env/env :encryption-key))]
    (fn [request]
      (let [decoded-session (try
                              (-> (get-in request [:headers "Cookie"])
                                  (http/parse-cookie)
                                  (get "id")
                                  (decode-session encryption-key))
                              ([err]
                               (logger/log {:msg err :attrs [:action "decode-session" :uri (get request :uri) :method (get request :method)] :level "error"})))
            request (put request :session decoded-session)
            response (handler request)
            session-value (get response :session)]
        (if (nil? session-value)
          response
          (put-in response [:headers "Set-Cookie"]
            (http/cookie-string "id" (encode-session session-value encryption-key)
              {"SameSite" "Strict" "HttpOnly" ""})))))))


(defn default-headers [handler &opt options]
  (default options {"X-Frame-Options" "SAMEORIGIN"
                    "X-XSS-Protection" "1; mode=block"
                    "X-Content-Type-Options" "nosniff"
                    "X-Download-Options" "noopen"
                    "X-Permitted-Cross-Domain-Policies" "none"
                    "Referrer-Policy" "strict-origin-when-cross-origin"})
  (fn [request]
    (let [response (handler request)]
      (update response :headers merge options))))


(defn body-parser [handler]
  (fn [request]
    (let [{:method method :body body} request]
      (if (and (= (string/ascii-lower method) "post")
               (not (nil? body)))
        (handler (put request :body (http/parse-body body)))
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
    (let [f (fiber/new (partial handler request) :e)
          res (resume f)]
      (if (not= (fiber/status f) :error)
        res
        (do
          (let [attrs (kvs (helper/select-keys request [:body :params]))]
            (logger/log {:msg res :attrs attrs :level "error"}))
          (debug/stacktrace f res)
          (if (= "development" (env/env :joy-env))
            (responder/respond :html
              (dev-error-page request res)
              :status 500)
            @{:status 500
              :body "Internal Server Error"
              :headers @{"Content-Type" "text/plain"}}))))))


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
