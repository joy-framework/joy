(import tester :prefix "" :exit true)
(import "src/joy" :prefix "")
(import path)
(import cipher)


(defn app-layout [response]
  (let [{:body body} response]
    (render :html
      (html
       (doctype :html5)
       [:html {:lang "en"}
        [:head
         [:meta {:charset "utf-8"}]
         [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
         [:link {:rel "stylesheet" :href "/test.css"}]
         [:title "joy test 1"]]
        [:body body]]))))


(defn account [request]
  (let [id (get-in request [:params :id])]
    (db/fetch [:account id])))


(def params
  (params
    (validates [:name :email :password] :required true)
    (permit [:name :email :password])))


(defn link-to [str route & args]
  (let [options (table ;args)]
    [:a (merge {:href (url-for route)} options)
      str]))


(defn home [request]
  [:div {:style "text-align: center"}
    [:h1 {:class "test"} "You've found joy!"]
    (link-to "Accounts" :index)])


(defn index [request]
  (let [{:session session} request
        accounts (db/fetch-all [:account])]
    [:div
     (link-to "New Account" :new)
     [:table
      [:thead
       [:tr
        [:th "id"]
        [:th "name"]
        [:th "email"]
        [:th "password"]
        [:th "updated-at"]
        [:th "created-at"]
        [:th]
        (when session
          [:th])]]
      [:tbody
       (map
        (fn [{:id id :name name :email email :password password :updated-at updated-at :created-at created-at}]
          [:tr
           [:td id]
           [:td name]
           [:td email]
           [:td password]
           [:td updated-at]
           [:td created-at]
           [:td
            [:a {:href (url-for :edit {:id id})}
             "Edit"]]
           (when (not (nil? session))
             [:td
              (form-for [request :destroy {:id id}]
               [:input {:type "submit" :value "Delete"}])])])
        accounts)]]]))


(defn show [request]
  (let [account (account request)
        {:id id :name name :email email :password password :created-at created-at :updated-at updated-at} account]
    [:table
     [:tr
      [:th "id"]
      [:th "name"]
      [:th "email"]
      [:th "password"]
      [:th "updated_at"]
      [:th "created_at"]]
     [:tr
      [:td id]
      [:td name]
      [:td email]
      [:td password]
      [:td updated-at]
      [:td created-at]]]))


(defn form [request account route]
  (let [{:name name :email email :password password} account]
    (form-for [request route account]
      (label :name "name")
      (text-field account :name)

      (label :email "email")
      (email-field account :email)

      (label :password "password")
      (password-field account :password)

      (submit "Save"))))


(defn new [request]
  (form request {} :create))


(defn create [request]
  (let [[errors account] (->> (params request)
                              (db/insert :account)
                              (rescue))]
    (if (nil? errors)
      (-> (redirect-to :index)
          (put :session account))
      (new (put request :errors errors)))))


(defn edit [request]
  (let [account (account request)]
    (form request account :patch)))


(defn patch [request]
  (let [account (account request)
        [errors account] (->> (params request)
                              (db/update :account (get account :id))
                              (rescue))]
    (if (nil? errors)
      (redirect-to :index)
      (edit (put request :errors errors)))))


(defn destroy [request]
  (let [account (account request)]
    (db/delete :account account)
    (redirect-to :index)))


(defn error-test [request]
  (error "test error"))


(defn new-upload [request]
  (form-with request {:route :upload-test :enctype "multipart/form-data"}

    (label :filename "filename")
    (file-field {} :filename)

    (submit "Save")))


(defn upload-test [request]
  (let [upload (get-in request [:multipart-body 0])
        temp-file (get upload :temp-file)
        ext (path/ext (get upload :filename))
        name (cipher/bin2hex (os/cryptorand 8))]
    # copy tempfile over to another file
    (with-file [f (string name ext) :wb]
      (file/write f (file/read temp-file :all)))
    (redirect-to :index)))


(defroutes routes
  [:get "/" home]
  [:get "/accounts" index]
  [:get "/accounts/new" new]
  [:post "/accounts" create]
  [:get "/accounts/:id" show]
  [:get "/accounts/:id/edit" edit]
  [:patch "/accounts/:id" patch]
  [:delete "/accounts/:id" destroy]
  [:get "/error-test" error-test]
  [:get "/uploads/new" new-upload]
  [:post "/uploads" upload-test])


(def app (-> (handler routes)
             (layout app-layout)
             #(logger)
             (csrf-token)
             (session)
             (file-uploads)
             (extra-methods)
             (query-string)
             (body-parser)
             (server-error)
             (x-headers)
             (static-files)))


(deftest
  (test "test the app"
    (= 200
       (let [response (app @{:uri "/" :method :get})]
         (get response :status)))))


(db/connect "test.sqlite3")

(db/execute "create table if not exists account (id integer primary key, name text not null unique, email text not null unique, password text not null, created_at integer not null default(strftime('%s', 'now')))")

#(server app 8000)

(db/disconnect)
