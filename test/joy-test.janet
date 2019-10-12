(import tester :prefix "" :exit true)
(import "src/joy" :as joy)

(defn layout [response]
  (let [{:body body} response]
    (joy/respond :html
      (joy/html
       (joy/doctype :html5)
       [:html {:lang "en"}
        [:head
         [:meta {:charset "utf-8"}]
         [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
         [:title "joy test 1"]]
        [:body body]]))))

(defn home [request]
  [:h1 {:style "text-align: center"} "You've found joy!"])

(defn hello [request]
  [:h1 (string "hello " (get-in request [:params :name]))])

(defn accounts [request]
  (let [{:db db :session session} request
        rows (joy/query db "select * from account")]
    [:table
     [:thead
      [:tr
       [:th "id"]
       [:th "name"]
       [:th "email"]
       [:th "password"]
       (when (not (nil? session))
        [:th ""])]]
     [:tbody
      (map
       (fn [{:id id :name name :email email :password password}]
         [:tr
          [:td id]
          [:td name]
          [:td email]
          [:td password]
          (when (not (nil? session))
            [:td
             [:form {:action (string "/accounts/" id) :method :post}
              [:input {:type "hidden" :name "_method" :value "delete"}]
              [:input {:type "submit" :value "Delete"}]]])])
       rows)]]))


(defn new [request]
  [:form {:action "/accounts" :method :post}
   [:input {:type "text" :name "name"}]
   [:input {:type "email" :name "email"}]
   [:input {:type "password" :name "password"}]
   [:input {:type "submit" :value "Create"}]])


(defn create [request]
  (let [{:body body :db db} request
        row (joy/insert db :account body)]
    (-> (joy/redirect "/accounts")
        (put :session {:id (get row :id)}))))


(defn delete [request]
  (let [{:db db :params params} request
        id (get params :id)
        row (joy/delete db :account id)]
    (joy/redirect "/accounts")))


(def routes
  (joy/routes
   [:get "/" home]
   [:get "/hello/:name" hello]
   [:get "/accounts" accounts]
   [:get "/accounts/new" new]
   [:post "/accounts" create]
   [:delete "/accounts/:id" delete]))


(def app (-> (joy/app routes)
             (joy/set-db "test.sqlite3")
             (joy/server-error)
             (joy/set-layout layout)
             (joy/session)
             (joy/static-files)
             (joy/logger)
             (joy/extra-methods)
             (joy/body-parser)))


#(joy/serve app 8000)


(deftest
  (test "joy get env variable with a single keyword"
    (do
      (os/setenv "JANET_ENV" "development")
      (= "development" (joy/env :janet-env))))

  (test "test everything"
    (= {:status 200 :headers {"Content-Type" "text/html; charset=utf-8"} :body `<!DOCTYPE HTML><html lang="en"><head><meta charset="utf-8" /><meta content="width=device-width, initial-scale=1" name="viewport" /><title>joy test 1</title></head><body><h1 style="text-align: center">You've found joy!</h1></body></html>`}
       (freeze
         (app @{:method :get :uri "/"})))))
