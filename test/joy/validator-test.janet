(import tester :prefix "" :exit true)
(import "src/joy/validator" :prefix "")

(def params
  (params :account
    (validates [:name :email :password] :required true)
    (validates :password :min-length 8)
    (validates :name :max-length 10)))

(deftest
  (test "invalid-keys with an empty value and blank? predicate"
    (= '(:a) (freeze (invalid-keys [:a] {:a ""} blank?))))

  (test "invalid-keys with a non-empty value and blank? predicate"
    (= (freeze (invalid-keys [:a] {:a "a"} blank?))
       '()))

  (test "params returns a valid dictionary when all required keys are present and not blank"
    (= (freeze (params {:account {:name "name" :email "email" :password "password"}}))
       {:account {:name "name" :email "email" :password "password"}}))

  (test "params raises an error when a dictionary doesn't have all required keys"
    (= (try
         (params {:account {:name ""}})
         ([err]
          (freeze err)))
       {:name "name is required" :email "email is required" :password "password is required"}))

  (test "params raises an error when min-length isn't met"
    (= (try
         (params {:account {:name "name" :email "email" :password "shorty"}})
         ([err]
          (freeze err)))
       {:password "password needs to be more than 8 characters"}))

  (test "params raises an error when max-length isn't met"
    (= (try
         (params {:account {:name "this is too long" :email "email" :password "correct horse battery staple"}})
         ([err]
          (freeze err)))
       {:name "name needs to be less than 10 characters"})))
