(import cipher)

(import ./http :as http)
(import ./env :as env)
(import ./helper :prefix "")


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
  (as-> (cookie request) ?
        (http/parse-cookie ?)
        (get ? "id")
        (decode-session ? key)))


(defn with-session
  `
  Add HttpOnly, SameSite=Lax cookie sessions to a handler.

  In production it sets the Secure; attribute for https only sessions by default.

  Override like this:

  (def app (-> (handler routes)
               (with-csrf-token)
               (with-session {"SameSite" "none" "HttpOnly" false})))

  False values in the dictionary will not show in the final Set-Cookie header.

  Example:

  (def routes (routes [:get "/" :home]
                      [:get "/login" :sessions/new]
                      [:post "/sessions" :sessions/create]
                      [:delete "/sessions" :sessions/delete]))

  (defn sessions/new [request]
    (form-for [request :sessions/create]
      [:input {:type "email" :name "email"}]
      [:button "Submit"]))

  (defn sessions/create [request]
    (def {:body body} request)

    (def user (table/slice body [:email]))

    # you probably want some validation that the user
    # exists here

    (-> (redirect-to :home)
        (put :session {:user user})))

  (defn sessions/delete [request]
    (-> (redirect-to :home)
        (put :session {})))

  (def app (-> (handler routes)
               (with-csrf-token)
               (with-session)))

  (app {:method :post :uri "/sessions" :body "email=test@example.com"})

  =>

  {:status 302 :body " " :session {:user {:email "test@example.com"}}}
  `
  [handler &opt cookie-options]
  (def cookie-options (if (dictionary? cookie-options)
                         cookie-options
                         {}))

  (def session-cookie-options {"SameSite" "Lax"
                               "HttpOnly" ""
                               "Path" "/"
                               "Secure" (when env/production? "")})

  (def cookie-options (->> (merge session-cookie-options cookie-options)
                           (pairs)
                           (filter |(truthy? (last $)))
                           (mapcat identity)
                           (apply struct)))

  (let [key (or (env/env :encryption-key)
                (env/env :csrf-token-key))]
    (fn [request]
      (let [request-session (or (session-from-request key request)
                                @{})
            response (handler (merge request request-session))
            session-value (or (get response :session)
                              (get request-session :session))]
          (let [joy-session {:session session-value :csrf-token (get response :csrf-token)}]
            (when (truthy? response)
              (let [cookie (get-in response [:headers "Set-Cookie"])
                    session-cookie (http/cookie-string "id" (encode-session joy-session key)
                                     cookie-options)]
                (if (indexed? cookie)
                  (update-in response [:headers "Set-Cookie"] array/push session-cookie)
                  (put-in response [:headers "Set-Cookie"] session-cookie)))))))))

(def session with-session)
