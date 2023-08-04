(import tester :prefix "" :exit true)
(import ../../src/joy/form-helper :prefix "")
(import ../../src/joy/router :prefix "")


(defn hello [request])
(defn hello1 [request])
(defn hello2 [request])
(def req {:masked-token "masked csrf token"})


(deftest
  (test "form-with"
    (deep= [:form @{:method "post" :action "/"} [] [:input {:type "hidden" :name "__csrf-token"}] nil]
           (form-with {} {:action "/" :method "post"})))

  (test "action-for"
    (let [routes (routes [:get "/" hello])]
      (= {:method :get :action "/"} (action-for :hello))))

  (test "action-for 2"
    (let [routes (routes [:post "/" hello1])]
      (= {:method :post :action "/"} (action-for :hello1))))

  (test "action-for 3"
    (let [routes (routes [:patch "/accounts/:id" hello2])]
      (= {:method :post :_method :patch :action "/accounts/1"} (action-for :hello2 {:id 1}))))

  (test "form-with 2"
    (deep= [:form @{:method :post :_method :patch :action "/accounts/2"}
            []
            [:input {:type "hidden" :name "__csrf-token"}]
            [:input @{:type "hidden" :value :patch :name "_method"}]]
           (form-with {} (action-for :hello2 {:id 2}))))

  (test "form-for"
    (is (deep= [:form {:method :post :_method :patch :action "/accounts/3"}
                [[:label @{:for "name"} "Account name"]
                 [:input @{:type "text" :name "name"}]
                 [:input @{:type "submit" :value "Save name"}]]
                [:input {:type "hidden" :name "__csrf-token" :value "masked csrf token"}]
                [:input @{:type "hidden" :name "_method" :value :patch}]]
               (form-for [req :hello2 {:id 3}]
                 (label :name "Account name")
                 (text-field :name)
                 (submit "Save name")))))

  (test "hidden-field"
    (is (deep= [:input @{:type "hidden" :name "hiddenfield" :value "hiddenvalue"}]
               (hidden-field :hiddenfield :value "hiddenvalue"))))

  (test "text-field"
    (is (deep= [:input @{:type "text" :name "text-field" :placeholder "Enter text" :class "a-class"}]
               (text-field :text-field :placeholder "Enter text" :class "a-class"))))

  (test "email-field"
    (is (deep= [:input @{:type "email" :name "email-field" :placeholder "Enter email" :class "a-class"}]
               (email-field :email-field :placeholder "Enter email" :class "a-class"))))

  (test "password-field"
    (is (deep= [:input @{:type "password" :name "password-field" :placeholder "Enter password" :class "a-class"}]
               (password-field :password-field :placeholder "Enter password" :class "a-class"))))

  (test "file-field"
    (is (deep= [:input @{:type "file" :name "file-field" :accept "image/*,.pdf" :class "a-class"}]
               (file-field :file-field :accept "image/*,.pdf" :class "a-class"))))

  (test "checkbox-field"
    (is (deep= [[:input @{:type "hidden" :name "finished" :value 0}]
                [:input @{:type "checkbox" :name "finished" :value 1 :checked ""}]]
               (checkbox-field :finished true))))

  (test "checkbox-field 2"
    (is (deep= [[:input @{:type "hidden" :name "finished" :value 0}]
                [:input @{:type "checkbox" :name "finished" :value 1 :class "class1 class2"}]]
               (checkbox-field :finished false :class "class1 class2")))))
