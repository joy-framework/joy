(import tester :prefix "" :exit true)
(import "src/joy" :as joy)

(deftest
  (test "joy get env variable with a single keyword"
    (do
      (os/setenv "PORT" "1234")
      (= "1234" (joy/env :port)))))
