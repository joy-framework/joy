(import ./helper :as helper)
(import ./http :as http)
(import ./logger :as logger)


(defn set-layout [handler layout]
  (fn [request]
    (let [response (handler request)
          response (if (indexed? response) @{:status 200 :body response} response)]
      (if (= 200 (get response :status))
        (layout response)
        response))))


(defn static-files [handler &opt root]
  (fn [request]
    (let [response (handler request)]
      (if (not= 404 (get response :status))
        response
        (let [{:method method} request]
          (if (some (partial = method) ["GET" "HEAD"])
            {:kind :static
             :root (or root "public")}))))))


(defn uuid-string []
  (let [rando (math/random)
        _ (os/shell (string "uuid=$(uuidgen); echo $uuid > " rando ".txt"))
        f (file/open (string rando ".txt") :r)
        uuid (string/trimr (file/read f :all))]
    (file/close f)
    (os/rm (string rando ".txt"))
    uuid))


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
      (if (= (string/ascii-lower method) "post")
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
