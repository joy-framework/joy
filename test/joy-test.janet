(import tester :prefix "" :exit true)
(import "src/joy" :as joy)
(import "src/joy/helper" :as helper)
(import "src/joy/middleware" :as middleware)

(defn layout [response]
  (let [{:body body} response]
    (joy/respond :html
      (joy/html
       (joy/doctype :html5)
       [:html {:lang "en"}
        [:head
         [:title "joy test 1"]]
        [:body body]]))))

(defn home [request]
  [:h1 {:style "text-align: center"} "hello world"])

(defn hello [request]
  [:h1 (string "hello " (helper/get-in request [:params :name]))])

(defn accounts [request]
  (let [rows (joy/query "select * from account where name = :name" {:name "sean"})]
    [:div
     (map
      (fn [{:name name :email email :password password}]
        [:div
         [:span {:style "margin-right: 10px"} name]
         [:span {:style "margin-right: 10px"} email]
         [:span {:style "margin-right: 10px"} password]])
      rows)]))

(defn new [request]
  [:form {:action "/accounts" :method "POST"}
   [:input {:type "text" :name "name"}]
   [:input {:type "email" :name "email"}]
   [:input {:type "password" :name "password"}]
   [:input {:type "submit" :value "Create"}]])

(defn create [request]
  (let [{:body body} request]
    (joy/insert :account body)
    (joy/redirect "/accounts")))

(def routes
  (joy/routes
   [:get "/" home]
   [:get "/hello/:name" hello]
   [:get "/accounts" accounts]
   [:get "/accounts/new" new]
   [:post "/accounts" create]))

(def app (-> (joy/app routes)
             (middleware/set-layout layout)
             (middleware/static-files)
             (joy/logger)))

(deftest
  (test "joy get env variable with a single keyword"
    (do
      (os/setenv "PORT" "1234")
      (= "1234" (joy/env :port))))

  (test "test everything"
    (= {:status 200 :headers {"Content-Type" "text/html"} :body `<!DOCTYPE HTML><html lang="en"><head><title>joy test 1</title></head><body><h1 style="text-align: center">hello world</h1></body></html>`}
       (app {:method "GET" :uri "/"}))))
