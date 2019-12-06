(import tester :prefix "" :exit true)
(import "src/joy/env" :as env)

(deftest
  (test "get env variable with a single keyword"
    (do
      (os/setenv "PORT" "1234")
      (= "1234" (env/env :port))))

  (test "parse .env test"
    (= {"X" "y"}
       (freeze
        (env/parse-dotenv "X=y\n"))))

  (test "parse .env test with a value with = in it"
    (= {"ENCRYPTION_KEY" "some-long-value-with=inside-of-it"}
       (freeze
        (env/parse-dotenv "ENCRYPTION_KEY=some-long-value-with=inside-of-it\n"))))

  (test "parse .env test with a value with three = signs"
    (= {"ENCRYPTION_KEY" "some-long-value-with=inside-of-it=="}
       (freeze
        (env/parse-dotenv "ENCRYPTION_KEY=some-long-value-with=inside-of-it==\n")))))

