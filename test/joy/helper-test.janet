(import tester :prefix "" :exit true)
(import "src/joy/helper" :prefix "")


(deftest
  (test "rescue returns an vector"
    (= ["some error" nil]
       (rescue
         (error "some error"))))

  (test "rescue returns an empty error vector"
    (= [nil "success"]
       (rescue
         "success")))

  (test "rescue returns a complex value on success"
    (= [nil {:a 1 :b 2}]
       (rescue
         {:a 1 :b 2})))

  (test "rescue returns a fn return value on success"
    (= [nil {:a 1 :b 2}]
       (rescue
         (identity {:a 1 :b 2})))))
