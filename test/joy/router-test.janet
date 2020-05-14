(import tester :prefix "" :exit true)
(import "src/joy/router" :prefix "")


(def ok {:status 200 :body ""})
(defn home [request] ok)
(defn accounts [request] ok)
(defn account [request]
  {:status 200 :body (get-in request [:params :id])})


(defn wildcard [request]
  (request :wildcard))


(defn auth-code [request]
  "auth-code")


(defroutes test-routes
  [:get "/" home]
  [:get "/test" home :qs]
  [:get "/accounts" accounts]
  [:get "/accounts/:id" account]
  [:get "/anchor" home :anchor]
  [:get "/anchor/:id" home :anchor-id]
  [:get "/accounts/:id/edit" identity :with-params]
  [:get "/auth-code" auth-code]
  [:patch "/accounts/:id" identity :accounts/patch]
  [:get "/wildcard/*" wildcard])


(deftest
  (test "get handler from routes"
    (= {:status 200 :body ""}
       ((handler test-routes) {:method :get :uri "/accounts"})))

  (test "get handler from routes"
      (= {:status 200 :body "1"}
         ((handler test-routes) {:method :get :uri "/accounts/1"})))

  (test "url-for with a route name"
    (= (url-for :home) "/"))

  (test "url-for with a query string"
    (= (url-for :qs {:? {"a" "1"}})
       "/test?a=1"))

  (test "url-for with an anchor string and a query string"
    (= (url-for :anchor {:? {"a" "1"} "#" "anchor"})
       "/anchor?a=1#anchor"))

  (test "url-for with url params an anchor string and a query string"
    (= (url-for :anchor-id {:id 1 :? {"a" "1"} "#" "anchor"})
       "/anchor/1?a=1#anchor"))

  (test "redirect-to with a function"
    (= (freeze
        (redirect-to :home))
       {:status 302 :body " " :headers {"Location" "/"}}))

  (test "redirect-to with a name and params"
    (= (freeze
        (redirect-to :with-params {:id 100}))
       {:status 302 :body " " :headers {"Location" "/accounts/100/edit"}}))

  (test "action-for with a name and params"
    (= (freeze
        (action-for :accounts/patch {:id 100}))
       {:_method :patch :method :post :action "/accounts/100"}))

  (test "wildcard route"
    (= "hello/world" ((handler test-routes) {:method :get :uri "/wildcard/hello/world"})))

  (test "query string route"
    (= "auth-code" ((handler test-routes) {:method :get :uri "/auth-code?code=12345"}))))
