(import tester :prefix "" :exit true)
(import "src/joy/router" :as router)
(import "src/joy/helper" :prefix "")

(defn home [request])

(deftest
  (test "fills in a param in the url"
    (= (router/route-url "/accounts/:id" {":id" "1"})
       "/accounts/1"))

  (test "fills in multiple params in the url"
    (= (router/route-url "/accounts/:id/todos/:todo-id" {":id" "1" ":todo-id" "2"})
       "/accounts/1/todos/2"))

  (test "ignores with no params"
    (= (router/route-url "/accounts" {})
       "/accounts"))

  (test "checks that two routes match"
    (true? (router/route-matches? [:get "/"] {:uri "/" :method :get})))

  (test "checks that two routes dont match on url"
    (false? (router/route-matches? [:get "/"] {:method :get :uri "/hello-world"})))

  (test "checks that two routes dont match on method"
    (false? (router/route-matches? [:get "/"] {:method :post :uri "/"})))

  (test "gets a param out of a url"
    (= {":id" "1"} (router/route-params "/accounts/:id" "/accounts/1")))

  (test "gets multiple params out of a url"
    (= {":id" "1" ":todo-id" "2"} (router/route-params "/accounts/:id/todos/:todo-id" "/accounts/1/todos/2")))

  (test "route-params with one segment"
    (= {} (router/route-params "/" "/")))

  (test "get handler from routes"
    (let [routes [[:get "/"]
                  [:get "/accounts" (fn [request] {:status 200 :body ""})]
                  [:get "/accounts/:id"]
                  [:post "/accounts"]]]
      (= {:status 200 :body ""}
       ((router/handler routes) {:method :get :uri "/accounts"}))))

  (test "get handler from routes"
    (let [routes [[:get "/"]
                  [:get "/accounts" (fn [request] {:status 200 :body ""})]
                  [:get "/accounts/:id" (fn [request] {:status 200 :body (get-in request [:params :id])})]
                  [:post "/accounts"]]]
      (= {:status 200 :body "1"}
       ((router/handler routes) {:method :get :uri "/accounts/1"}))))

  (test "middleware"
    (let [mw (fn [handler]
               (fn [request] (handler (put request :a 1))))
          routes (router/routes
                   (router/middleware mw
                     [:get "/" (fn [request] {:status 200 :body (get request :a)})]))]
      (= {:status 200 :body 1}
        ((router/handler routes) {:method :get :uri "/"}))))

  (test "two middleware fns"
    (let [mw (fn [handler]
               (fn [request] (handler (put request :a 1))))
          mw2 (fn [handler]
                (fn [request] (handler (put request :b 2))))
          routes (router/routes
                   (router/middleware mw mw2
                     [:get "/" (fn [request] {:status 200 :body (+ (get request :b) (get request :a))})]))]
      (= {:status 200 :body 3}
        ((router/handler routes) {:method :get :uri "/"}))))

  (test "url-for with a function"
    (let [routes (router/route-table [[:get "/" home]])]
      (= (router/url-for {:routes routes} :home) "/")))

  (test "url-for with a route name"
    (let [routes (router/route-table [[:get "/" home :home2]])]
      (= (router/url-for {:routes routes} :home2) "/")))

  (test "url-for with a query string"
    (let [routes (router/route-table [[:get "/test" home :qs]])]
      (= (router/url-for {:routes routes} :qs {:? {"a" "1"}}) "/test?a=1")))

  (test "url-for with an anchor string and a query string"
    (let [routes (router/route-table [[:get "/anchor" home :anchor]])]
      (= (router/url-for {:routes routes} :anchor {:? {"a" "1"} "#" "anchor"}) "/anchor?a=1#anchor")))

  (test "url-for with url params an anchor string and a query string"
    (let [routes (router/route-table [[:get "/anchor/:id" home :anchor-id]])]
      (= (router/url-for {:routes routes} :anchor-id {:id 1 :? {"a" "1"} "#" "anchor"}) "/anchor/1?a=1#anchor")))

  (test "redirect-to with a function"
    (let [routes (router/route-table [[:get "/" home]])]
      (= (freeze
          (router/redirect-to {:routes routes} :home))
         {:status 302 :body "" :headers {"Location" "/"}})))

  (test "redirect-to with a name and params"
    (let [routes (router/route-table [[:get "/accounts/:id/edit" identity :with-params]])]
      (= (freeze
          (router/redirect-to {:routes routes} :with-params {:id 100}))
         {:status 302 :body "" :headers {"Location" "/accounts/100/edit"}})))

  (test "action-for with a name and params"
    (let [routes (router/route-table [[:patch "/accounts/:id" identity :accounts/patch]])]
      (= (freeze
          (router/action-for {:routes routes} :accounts/patch {:id 100}))
         {:_method :patch :method :post :action "/accounts/100"}))))
