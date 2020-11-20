(import tester :prefix "" :exit true)
(import "src/joy" :prefix "")
(import cipher)

# turn off a bunch of middleware that isn't necessary for some of these tests
(def basic-app {:logger false
                :session false
                :csrf-token false
                :x-headers false})


(defsuite
  (test "get request with no routes returns plain text 404"
        (is (deep= @{:status 404
                     :body "not found"
                     :headers @{"Content-Type" "text/plain"}}

                   (let [app (app basic-app)]
                     (app {:method "GET" :uri "/"})))))


  (test "get request with a matching route with text/plain helper returns plain text 200"
        (is (deep= @{:status 200
                     :body "home"
                     :headers @{"Content-Type" "text/plain"}}

                   (let [# route functions
                         home (fn [_] (text/plain "home"))

                         # routes
                         routes {:routes [[:get "/" home]]}

                         # app with a bunch of middleware turned off
                         app (app (merge basic-app routes))]

                     (app {:method "GET"
                           :uri "/"})))))


  (test "post request without csrf protection returns 302"
        (is (deep= @{:status 302
                     :body " "
                     :headers @{"Turbolinks-Location" "/"
                                "Location" "/"}}

                   (let [# route functions
                         post (fn [req] (redirect "/"))
                         home (fn [req] (text/plain "home"))

                         # routes
                         routes {:routes [[:get "/" home]
                                          [:post "/post" post]]}

                         # app
                         app (app (merge basic-app routes))]

                     (app {:method "POST"
                           :uri "/post"
                           :headers {"Content-Type" "application/x-www-form-urlencoded"}
                           :body "name=value"})))))


  (test "post request with csrf protection and no csrf token key returns 403"
        (is (deep= @{:status 403
                     :body "Invalid CSRF Token"
                     :headers @{"Content-Type" "text/plain"}}

                   (let [# route functions
                         post (fn [req] (redirect "/"))
                         home (fn [req] (text/plain "home"))

                         # routes
                         routes {:routes [[:get "/" home]
                                          [:post "/post" post]]}

                         # app
                         app (app (merge basic-app routes {:session true
                                                           :csrf-token true}))

                         response (app {:method "POST"
                                        :uri "/post"
                                        :headers {"Content-Type" "application/x-www-form-urlencoded"}
                                        :body "name=value"})]

                     (update response :headers table/slice ["Content-Type"])))))


  (test "post request with csrf protection and a csrf token key returns 302"
        (is (deep= @{:status 302
                     :body " "
                     :headers @{"Turbolinks-Location" "/"
                                "Location" "/"}}

                   (let [_ (os/setenv "CSRF_TOKEN_KEY" (cipher/encryption-key))

                         # route functions
                         post (fn [req] (redirect "/"))
                         form (fn [req] (text/plain (csrf-token-value req)))
                         home (fn [req] (text/plain "home"))

                         # routes
                         routes {:routes [[:get "/" home]
                                          [:post "/post" post]
                                          [:get "/form" form]]}

                         # app
                         app (app (merge basic-app routes {:session true
                                                           :csrf-token true}))

                         # grab the session cookie and the csrf token
                         {:body body :headers headers} (app {:method "GET"
                                                             :uri "/form"})

                         # set up headers with session cookie
                         headers {"Content-Type" "application/x-www-form-urlencoded"
                                  "Cookie" (get headers "Set-Cookie")}

                         # send those headers and the csrf token to /post
                         response (app {:method "POST"
                                        :uri "/post"
                                        :headers headers
                                        :body (string "name=value&__csrf-token=" body)})]

                      (-> (update response :headers table/slice ["Location" "Turbolinks-Location"])
                          (table/slice [:status :body :headers]))))))


  (test "get request can return json"
        (is (deep= @{:status 200
                     :body @`{"array":[1,2,3],"name":"value"}`
                     :headers @{"Content-Type" "application/json"}}

                   (let [# route functions
                         home (fn [_] (application/json {:name "value"
                                                         :array [1 2 3]}))

                         # routes
                         routes {:routes [[:get "/" home]]}

                         # app with a bunch of middleware turned off
                         app (app (merge basic-app routes))]

                     (app {:method "get"
                           :uri "/"})))))


  (test "post can parse json body"
        (is (deep= @{:status 200
                     :body @`{"array":[1,2,3],"name":"value"}`
                     :headers @{"Content-Type" "application/json"}}

                   (let [# route functions
                         post (fn [req] (application/json (req :body)))

                         # routes
                         routes {:routes [[:post "/post" post]]}

                         # app with a bunch of middleware turned off
                         app (app (merge basic-app routes))]

                     (app {:method :post
                           :uri "/post"
                           :headers {"Content-Type" "application/json"}
                           :body `{"array":[1,2,3],"name":"value"}`})))))


  (test "can parse application/x-www-form-urlencoded body"
        (is (deep= @{:status 200
                     :body `@{:name "value"}`
                     :headers @{"Content-Type" "text/plain"}}

                   (let [# route functions
                         post (fn [req] (text/plain (string/format "%q" (req :body))))

                         # routes
                         routes {:routes [[:post "/post" post]]}

                         # app with a bunch of middleware turned off
                         app (app (merge basic-app routes))]

                     (app {:method :post
                           :uri "/post"
                           :headers {"Content-Type" "application/x-www-form-urlencoded"}
                           :body "name=value"}))))))


