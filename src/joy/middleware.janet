(import ./helper :as helper)
(import ./http :as http)
(import ./logger :as logger)
(import ./env :as env)
(import ./db :as db)
(import uuid)
(import cipher)
(import json)
(import codec)


(defn set-layout [handler layout]
  (fn [request]
    (let [response (handler request)
          response (if (indexed? response) @{:status 200 :body response} response)]
      (if (= 200 (get response :status))
        (layout response)
        response))))


(defn set-db [handler conn]
  (fn [request]
    (db/with-connection [db conn]
      (handler (put request :db db)))))


(defn static-files [handler &opt root]
  (fn [request]
    (let [response (handler request)]
      (if (not= 404 (get response :status))
        response
        (let [{:method method} request]
          (if (some (partial = method) ["GET" "HEAD"])
            {:kind :static
             :root (or root "public")}))))))


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


(defn decode-session [str encryption-key]
  (when (not (nil? str))
    (let [decrypted (->> (codec/decode str)
                         (cipher/decrypt encryption-key))]
      (when (not (nil? decrypted))
        (json/decode decrypted)))))


(defn encode-session [val encryption-key]
  (when (not (nil? val))
    (->> (json/encode val)
         (string)
         (cipher/encrypt encryption-key)
         (codec/encode))))


(defn session [handler]
  (let [encryption-key (codec/decode
                        (env/get-env :encryption-key))]
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


(defn server-error [handler &opt options]
  (default options {:ignore-keys [:password :confirm-password]})
  (fn [request]
    (try
      (handler request)
      ([err]
       (let [{:body body :params params} request
             body (apply helper/dissoc body (get options :ignore-keys))]
         (logger/log {:msg err :attrs [:body body :params params] :level "error"}))
       @{:status 500 :body "Oops 500" :headers @{"Content-Type" "text/plain"}}))))
