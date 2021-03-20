(import tester :prefix "" :exit true)
(import ../../src/joy/helper :prefix "")


(deftest
  (test "rescue throws an error"
    (try
      (rescue
        (error "some error"))
      ([err]
       (= err "some error"))))


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
         (identity {:a 1 :b 2}))))

  (test "rescue catches any errors thrown by raise"
    (= ["some error" nil]
       (rescue
         (raise "some error"))))

  (test "rescue catches specific errors thrown by raise when id passed"
    (= ["some error" nil]
       (rescue
         (raise "some error" :specific)
         :specific)))

  (test "no id rescue ignores errors thrown by raise when id is passed"
    (try
      (rescue
        (raise "some error" :specific))
      ([err] (= err {:error "some error" :id :specific}))))

  (test "rescue returns a vector with no errors"
    (= [nil {:a 1}]
       (rescue
        ((fn [request] {:a 1}) nil)))))
