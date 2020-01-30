(import tester :prefix "" :exit true)
(import "src/joy/logger" :as logger)

(deftest
  (test "log"
    (let [ts "timestamp"]
      (= (string ts ` at=info msg="Started GET /" method=GET`)
         (logger/log-string {:ts ts :level "info" :msg "Started GET /" :attrs [:method "GET"]}))))

  (let [buf (buffer)]
    (setdyn :out buf)
    (test "logger"
      (= {:status 200 :body ""}
         ((logger/logger (fn [request] {:status 200 :body ""}))
          {:method :get :uri "/hello"})))
    (setdyn :out stdout)))
