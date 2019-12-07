(import tester :prefix "" :exit true)
(import "src/server" :prefix "")

(deftest
  (test "test the app"
    (= 200
       (let [response (app {:uri "/" :method :get})]
         (get response :status)))))


