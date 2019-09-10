(import tester :prefix "" :exit true)
(import "src/joy" :prefix "")

(defn layout [response]
  (let [{:body body} response]
    (respond :html
      (html
       (doctype :html5)
       [:html {:lang "en"}
        [:head
         [:title "joy test 1"]]
        [:body body]]))))

(defn home [request]
  [:h1 {:style "text-align: center"} "you've found joy!"])

(defn hello [request]
  [:h1 (string "hello " (get-in request [:params :name]))])

(defn accounts [request]
  (let [rows (with-db-connection [db "dev.sqlite3"]
                (query db "select * from account"))]
    [:table
     [:thead
      [:tr
       [:th "name"]
       [:th "email"]
       [:th "password"]]]
     [:tbody
      (map
       (fn [{:name name :email email :password password}]
         [:tr
          [:td name]
          [:td email]
          [:td password]])
       rows)]]))

(defn new [request]
  [:form {:action "/accounts" :method "POST"}
   [:input {:type "text" :name "name"}]
   [:input {:type "email" :name "email"}]
   [:input {:type "password" :name "password"}]
   [:input {:type "submit" :value "Create"}]])

(defn create [request]
  (let [{:body body} request]
    (with-db-connection [db "dev.sqlite3"]
      (insert :account body))
    (redirect "/accounts")))

(def routes
  (routes
   [:get "/" home]
   [:get "/hello/:name" hello]
   [:get "/accounts" accounts]
   [:get "/accounts/new" new]
   [:post "/accounts" create]))

(def app (-> (app routes)
             (set-layout layout)
             (set-cookie)
             (static-files)
             (body-parser)
             (logger)))

(deftest
  (test "joy get env variable with a single keyword"
    (do
      (os/setenv "JANET_ENV" "development")
      (= "development" (env :janet-env))))

  (test "test everything"
    (= {:status 200 :headers {"Content-Type" "text/html" "Set-Cookie" "id=id; SameSite=Strict; HttpOnly"} :body `<!DOCTYPE HTML><html lang="en"><head><title>joy test 1</title></head><body><h1 style="text-align: center">you've found joy!</h1></body></html>`}
       (freeze
        (app {:method "GET" :uri "/"})))))
