(import tester :prefix "" :exit true)
(import ../../src/joy/validator :prefix "")
(import ../../src/joy/helper :prefix "")

(def account-params
  (params :accounts
    (validates [:name :email :password] :required true)
    (validates :password :min-length 8)
    (validates :name :max-length 10)
    (validates :name :matches '(between 3 20 (range "AZ" "az" "09")))
    (validates :email :email true)))

(deftest
  (test "params returns a valid dictionary when all required keys are present and not blank"
    (deep= (account-params {:body {:name "name" :email "test@example.com" :password "password"}})
           @{:name "name" :email "test@example.com" :password "password" :db/table :accounts}))

  (test "params raises an error when a dictionary doesn't have all required keys"
    (= (->> (account-params {:body {:name ""}})
            (rescue-from :params)
            (first)
            (freeze))
       {:name "name is required" :email "email is required" :password "password is required"}))

  (test "params raises an error when min-length isn't met"
    (= (->> (account-params {:body {:name "name" :email "test@example.com" :password "shorty"}})
            (rescue-from :params)
            (first)
            (freeze))
       {:password "password needs to be more than 8 characters"}))

  (test "params raises an error when max-length isn't met"
    (= (->> (account-params {:body {:name "this is too long" :email "test@example.com" :password "correct horse battery staple"}})
            (rescue-from :params)
            (first)
            (freeze))
       {:name "name needs to be less than 10 characters"}))

  (test "params raises an error when a peg doesn't match"
    (= (->> (account-params {:body {:name "na" :email "test@example.com" :password "correct horse battery staple"}})
            (rescue-from :params)
            (first)
            (freeze))
       {:name "name needs to match (between 3 20 (range \"AZ\" \"az\" \"09\"))"}))

  (test "params raises an error with an invalid email"
    (= (->> (account-params {:body {:name "name" :email "not an email" :password "correct horse battery staple"}})
            (rescue-from :params)
            (first)
            (freeze))
       {:email "email needs to be an email"}))

  (let [account-params (params :accounts
                          (validates :name :required true :message "can't be blank"))]
    (test "params handles custom error messages"
      (deep= (->> (account-params {:body {:name ""}})
                  (rescue)
                  (first))
             @{:name "name can't be blank"})))

  (let [test-params (params :accounts
                      (validates :website :uri true))]
    (test "uri validator"
      (deep= (-> (test-params {:body {:website "example.com"}})
                 (rescue)
                 (last))
             @{:website "example.com" :db/table :accounts})))

  (let [todo (body :todos
               (validates :name :required true)
               (permit :name :finished))]

    (test "body returns errors"
      (is (deep= @{:db/errors @{:name "name is required"} :db/table :todos}
                 (todo {:body nil}))))

    (test "body with permit restricts keys"
      (is (deep= @{:db/table :todos :finished 1 :name "name"}
                 (todo {:body {:finished 1 :name "name" :other "other"}}))))))
