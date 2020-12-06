(import ./helper :prefix "")
(import ./http :as http)
(import ./logger :as logger)
(import ./env :as env)
(import ./responder :as responder)
(import ./html :as html)
(import cipher)
(import path)
(import json)


(defn layout
  `Wraps responses returning indexed datastructures (tuples or arrays) in the given layout-fn

  Example:

  (defn my-layout [{:body body :request request}]
    (text/html
      (doctype :html5)
      [:html {:lang "en"}
       [:head
        [:title "title"]
        [:meta {:charset "utf-8"}]
        [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
        [:meta {:name "csrf-token" :content (authenticity-token request)}]]
       [:body body]]))

  (defn home [req]
    [:h1 "home"])

  (defn crash-override [req]
    (text/html [:h1 "home"]))

  (defroutes routes
    [:get "/" home]
    [:get "/crash-override" crash-override])

  (def app (handler routes))

  (def app-with-layout (as-> (handler routes) ?
                             (layout ?)))

  (app {:method :get :uri "/"}) # => [:h1 "home"]
  (app-with-layout {:method :get :uri "/"}) # => {:status 200 :body "<html>...</html>" ...}
  (app-with-layout {:method :get :uri "/crash-override"}) # => {:status 200 :body "<h1>home</h1>" ...}
  `
  [handler layout-fn]
  (fn [request]
    (let [response (handler request)]
      (if (and (function? layout-fn)
               (indexed? response))
        (layout-fn @{:status 200 :body response :request request})
        response))))


(defn static-files
  `Skips any handlers and returns static files if path is a head/get and matches
   the given file + pathname.

   Example:

   (def routes (routes [:get "/" :home]))

   (def app (as-> (handler routes)
                  (static-files)))

   (app {:get "/" :uri "/public/app.css"}) => {:status 200 :body ".red { color: red; }" :headers {"Content-Type" "text/css"}}
  `
  [handler &opt root]
  (default root "./public")
  (fn [request]
    (let [{:uri uri} request
          filename (path/join root uri)]
      (if (and (or (get? request) (head? request))
               (path/ext filename)
               (file-exists? filename))
        @{:file filename :level "verbose"}
        (handler request)))))


(defn x-headers [handler &opt opts]
  (default opts @{})
  (def options @{"X-Frame-Options" "SAMEORIGIN"
                 "X-XSS-Protection" "1; mode=block"
                 "X-Content-Type-Options" "nosniff"
                 "X-Download-Options" "noopen"
                 "X-Permitted-Cross-Domain-Policies" "none"
                 "Referrer-Policy" "strict-origin-when-cross-origin"})
  (def options (merge options opts))
  (fn [request]
    (when-let [response (handler request)]
      (update response :headers merge options))))


(defn body-parser [handler]
  (fn [request]
    (let [{:body body} request]
      (if (and body
               (or (post? request)
                   (patch? request)
                   (put? request)
                   (delete? request))
               (form? request))
        (handler (merge request {:body (http/parse-body body)}))
        (handler request)))))


(defn json-body-parser [handler]
  (fn [request]
    (let [{:body body} request]
      (if (and body
               (json? request))
        (handler (merge request {:body (json/decode body true)}))
        (handler request)))))


(defn- dev-error-page [request err buf]
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
         (string/format "%m" request)]]]

      [:div {:style "padding: 20px"}
       [:strong "Stacktrace"]
       [:pre {:style "white-space: pre-wrap"}
        [:code
         (string buf)]]]]]))


(defn server-error [handler]
  (fn [request]
    (try
      (handler request)
      ([err fib]
       (debug/stacktrace fib err)
       (let [buf @""]
         (setdyn :err buf)
         (debug/stacktrace fib err)
         (setdyn :err :stderr)

         (if env/development?
           (responder/respond :html
             (dev-error-page request err buf)
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


(defn cors [handler &opt opts]
  `This middleware will allow CORS access. Both simple and
   preflight OPTIONS requests are handled.

   A set of minimal, sensible default CORS options are provided,
   but can and should be customized by the user with their desired settings.

   The defaults allow only GET and OPTIONS requests from all origins with a
   24-hour max-age.`
  (default opts @{})
  (def default-options @{"Access-Control-Allow-Origin" "*"
                         "Access-Control-Allow-Methods" "GET, OPTIONS"
                         "Access-Control-Allow-Headers" "Content-Type"
                         "Access-Control-Max-Age" 86400})
  (def options (merge default-options opts))
  (fn [request]
    (if (= "OPTIONS" (get request :method))
      @{:status 204 :body "" :headers options}
      (let [response (handler request)]
        (when response
          (update response :headers merge options))))))


(defn json-response [handler]
  (fn [request]
    (let [body (handler request)]
      (responder/application/json body))))
