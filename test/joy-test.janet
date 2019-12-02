(import tester :prefix "" :exit true)
(import "src/joy" :prefix "")


(defn layout [response]
  (let [{:body body} response]
    (render :html
      (html
       (doctype :html5)
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

(defn index [request]
  (let [{:db db :session session} request
        rows (query db "select * from account")]
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
  [:form (action-for request :create)
   [:div
    [:label {:for "name"} "Name"]
    [:br]
    [:input {:type "text" :name "name"}]]
   [:div
    [:label {:for "email"} "Email"]
    [:br]
    [:input {:type "email" :name "email"}]]
   [:div
    [:label {:for "password"} "Password"]
    [:br]
    [:input {:type "password" :name "password"}]]
   [:div
    [:input {:type "submit" :value "Create"}]]])


(def insert-params
  (params
    (validates [:name :email :password] :required true)))


(defn create [request]
  (let [{:body body :db db} request
        [errors account] (->> (insert-params body)
                              (insert db :account)
                              (rescue))]
    (if (nil? errors)
      (-> (redirect-to request :index)
          (put :session account))
      (new (put request :errors errors)))))


(defn edit [request])


(defn patch [request])


(defn destroy [request]
  (let [{:db db :params params} request
        id (get params :id)
        row (delete db :account id)]
    (redirect-to request :index)))


(defn error-test [request]
  (error "test error"))


(def routes
  (routes
   [:get "/" home]
   [:get "/error-test" error-test]
   [:get "/hello/:name" hello]
   [:get "/accounts" index]
   [:get "/accounts/new" new]
   [:post "/accounts" create]
   [:get "/accounts/:id/edit" edit]
   [:patch "/accounts/:id" patch]
   [:delete "/accounts/:id" destroy]))


(def app (-> (app routes)
             (set-db "test.sqlite3")
             (server-error)
             (set-layout layout)
             (session)
             (static-files)
             (logger)
             (extra-methods)
             (query-string)
             (body-parser)))


# (with-db-connection [conn "test.sqlite3"])
#   (execute conn "create table if not exists account (id integer primary key, name text not null unique, email text not null unique, password text not null, created_at integer not null default(strftime('%s', 'now')))")
#
# (serve app 8000)


(deftest
  (test "joy get env variable with a single keyword"
    (do
      (os/setenv "JOY_ENV" "development")
      (= "development" (env :joy-env))))

  (test "test everything"
    (= {:status 200 :headers {"Content-Type" "text/html; charset=utf-8"} :body `<!DOCTYPE HTML><html lang="en"><head><meta charset="utf-8" /><meta content="width=device-width, initial-scale=1" name="viewport" /><title>joy test 1</title></head><body><h1 style="text-align: center">You've found joy!</h1></body></html>`}
       (freeze
         (app @{:method :get :uri "/"})))))
