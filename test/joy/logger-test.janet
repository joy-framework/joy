(import tester :prefix "" :exit true)
(import "src/joy/logger" :as logger)

(deftest
  (test "format-key-value-pair with a number"
    (= "duration=10" (logger/format-key-value-pairs [:duration 10])))

  (test "message creates a logfmt string"
    (= `at=info msg="Started GET /"` (logger/message "info" "Started GET /")))

  (test "message creates a logfmt string from a mixed type struct"
    (= `at=info msg="Started GET /" method=GET duration=10`
       (logger/message "info" "Started GET /" [:method "GET" :duration 10])))

  (test "message creates a logfmt string from a struct with an empty struct"
    (= `at=info msg="Started GET /" method=GET duration=10 params={}`
       (logger/message "info" "Started GET /" [:method "GET" :duration 10 :params {}])))

  (test "message with a nil value"
    (= `at=info msg="Started GET /" method=GET params={}`
       (logger/message "info" "Started GET /" [:method "GET" :duration nil :params {}])))

  (test "log"
    (let [ts (logger/timestamp)]
      (= (string ts ` at=info msg="Started GET /" method=GET`)
         (logger/log {:ts ts :level "info" :msg "Started GET /" :attrs [:method "GET"]}))))

  (test "middleware"
    (= {:status 200 :body ""}
       ((logger/middleware (fn [request] {:status 200 :body ""}))
        {:method "GET" :uri "/hello" :params {}}))))
