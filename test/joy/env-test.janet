(import tester :prefix "" :exit true)
(import "src/joy/env" :as env)

(deftest
  (test "get env variable with a single keyword"
    (do
      (os/setenv "PORT" "1234")
      (= "1234" (env/get-env :port)))))
