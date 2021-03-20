(import tester :prefix "" :exit true)
(import ../../src/joy/form-helper :prefix "")
(import ../../src/joy/router :prefix "")


(defn hello [request])
(defn hello1 [request])
(defn hello2 [request])


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

  (test "checkbox-field"
    (is (deep= [[:input {:type "hidden" :name :finished :value 0}]
                [:input @{:type "checkbox" :name :finished :value 1 :checked ""}]]

               (checkbox-field {:finished 1} :finished))))

  (test "checkbox-field"
    (is (deep= [[:input {:type "hidden" :name :finished :value 0}]
                [:input @{:type "checkbox" :name :finished :value 1 :checked "" :class "class1 class2"}]]

               (checkbox-field {:finished 1} :finished :class "class1 class2")))))
