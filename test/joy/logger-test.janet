(import tester :prefix "" :exit true)
(import ../../src/joy/logger :as logger)

(deftest
  (let [buf (buffer)]
    (setdyn :out buf)
    (test "logger"
      (let [response @{:status 200 :body "" :headers {"Content-Type" "application/json"}}]
        (deep= response
               ((logger/logger (fn [request] response))
                @{:method :get :uri "/hello" :headers {"Content-Type" "text/plain"
                                                       "Accept" "text/plain"}}))))
    (setdyn :out stdout))

  (let [buf (buffer)]
    (setdyn :out buf)
    (test "logger levels"
      (let [response @{:status 200 :body "" :level "verbose" :headers {"Content-Type" "application/json"}}]
        ((logger/logger (fn [request] response))
         @{:method :get :uri "/levels" :headers {"Accept" "text/plain"}})

        (empty? buf)))
    (setdyn :out stdout)))
