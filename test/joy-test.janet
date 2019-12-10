(import tester :prefix "" :exit true)
(import "src/joy" :prefix "")


(defn app-layout [response]
  (let [{:body body} response]
    (render :html
      (html
       (doctype :html5)
       [:html {:lang "en"}
        [:head
         [:meta {:charset "utf-8"}]
         [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
         [:link {:rel "stylesheet" :href "/css/test.css"}]
         [:title "joy test 1"]]
        [:body body]]))))


(defn set-account [handler]
  (fn [request]
    (let [{:db db :params params} request
          id (get params :id)
          account (fetch db [:account id])]
      (handler
       (merge request {:account account :id id})))))


(def params
  (params
    (validates [:name :email :password] :required true)
    (permit [:name :email :password])))


(defn home [request]
  [:h1 {:class "test"} "You've found joy!"])


(defn index [request]
  (let [{:db db :session session} request
        accounts (fetch-all db [:account])]
    [:table
     [:thead
      [:tr
       [:th "id"]
       [:th "name"]
       [:th "email"]
       [:th "password"]
       [:th]
       (when (not (nil? session))
         [:th])]]
     [:tbody
      (map
       (fn [{:id id :name name :email email :password password}]
         [:tr
          [:td id]
          [:td name]
          [:td email]
          [:td password]
          [:td
           [:a {:href (url-for request :edit {:id id})}
            "Edit"]]
          (when (not (nil? session))
            [:td
             (form-for [request :destroy {:id id}]
              [:input {:type "submit" :value "Delete"}])])])
       accounts)]]))


(defn show [request]
  (let [{:account account} request
        {:id id :name name :email email :password password :created_at created-at} account]
    [:table
     [:tr
      [:th "id"]
      [:th "name"]
      [:th "email"]
      [:th "password"]
      [:th "created_at"]]
     [:tr
      [:td id]
      [:td name]
      [:td email]
      [:td password]
      [:td created-at]]]))


(defn form [request route]
  (let [account (get request :account {})
        {:name name :email email :password password} account]
    (form-for [request route account]
      (label :name)
      (text-field account :name)

      (label :email)
      (email-field account :email)

      (label :password)
      (password-field account :password)

      (submit "Create"))))


(defn new [request]
  (form request :create))


(defn create [request]
  (let [{:db db} request
        [errors account] (->> (params request)
                              (insert db :account)
                              (rescue))]
    (if (nil? errors)
      (-> (redirect-to request :index)
          (put :session account))
      (new (put request :errors errors)))))


(defn edit [request]
  (form request :patch))


(defn patch [request]
  (let [{:db db :id id} request
        [errors account] (->> (params request)
                              (update db :account id)
                              (rescue))]
    (if (nil? errors)
      (redirect-to request :index)
      (edit (put request :errors errors)))))


(defn destroy [request]
  (let [{:db db :id id} request]
    (delete db :account id)
    (redirect-to request :index)))


(defn error-test [request]
  (error "test error"))


(def account-routes
  (routes
    [:get "/accounts" index]
    [:get "/accounts/new" new]
    [:post "/accounts" create]
    (middleware set-account
      [:get "/accounts/:id" show]
      [:get "/accounts/:id/edit" edit]
      [:patch "/accounts/:id" patch]
      [:delete "/accounts/:id" destroy])))


(def home-routes
  (routes
   [:get "/" home]
   [:get "/error-test" error-test]))


(def routes
  (routes
    home-routes
    account-routes))


(def app (-> (app routes)
             (db "test.sqlite3")
             (layout app-layout)
             (logger)
             (csrf-token)
             (session)
             (extra-methods)
             (query-string)
             (body-parser)
             (server-error)
             (x-headers)
             (static-files)))


# (with-db-connection [conn "test.sqlite3"]
#   (execute conn "create table if not exists account (id integer primary key, name text not null unique, email text not null unique, password text not null, created_at integer not null default(strftime('%s', 'now')))"))
#
# (server app 8000)


(deftest
  (test "test the app"
    (= 200
       (let [response (app @{:uri "/" :method :get})]
         (get response :status)))))
