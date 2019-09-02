(import tester :prefix "" :exit true)
(import "src/joy/router" :as router)
(import "src/joy/helper" :prefix "")

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
       ((router/handler routes) {:method :get :uri "/accounts/1"})))))
