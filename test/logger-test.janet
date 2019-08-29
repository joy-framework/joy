(import tester :prefix "" :exit true)
(import "src/joy/logger" :as logger)
(import json)

(deftest
  (test "format-key-value-pair with a number"
    (= "duration=10" (logger/format-key-value-pairs [:duration 10])))

  (test "message creates a logfmt string"
    (= `at=info msg="Started GET /"`
       (logger/message "info" "Started GET /")))

  (test "message creates a logfmt string from a mixed type struct"
    (= `at=info msg="Started GET /" request-method=GET duration=10`
       (logger/message "info" "Started GET /" [:request-method "GET" :duration 10])))

  (test "message creates a logfmt string from a struct with an empty struct"
    (= `at=info msg="Started GET /" request-method=GET duration=10 params={}`
       (logger/message "info" "Started GET /" [:request-method "GET" :duration 10 :params {}])))

  (test "message with a nil value"
    (= `at=info msg="Started GET /" request-method=GET params={}`
       (logger/message "info" "Started GET /" [:request-method "GET" :duration nil :params {}])))

  (test "log"
    (let [ts (logger/timestamp)]
      (= (string ts ` at=info msg="Started GET /" request-method=GET`)
         (logger/log {:ts ts :level "info" :msg "Started GET /" :attrs [:request-method "GET"]}))))

  (test "serialize with struct"
    (= `{"a":1}` (logger/serialize {:a 1})))

  (test "serialize with table"
    (= `{"a":1}` (logger/serialize @{:a 1})))

  (test "serialize with tuple"
    (= "[1,2,3]" (logger/serialize [1 2 3])))

  (test "serialize with array"
    (= "[1,2,3]" (logger/serialize @[1 2 3])))

  (test "serialize with string"
    (= "hello" (logger/serialize "hello")))

  (test "serialize with number"
    (= "1" (logger/serialize 1)))

  (test "middleware"
    (= {:status 200 :body ""}
       ((logger/middleware (fn [request] {:status 200 :body ""}))
        {:request-method :get :uri "/hello" :params {}}))))
