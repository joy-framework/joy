(import tester :prefix "" :exit true)
(import "src/joy/http" :as http)


(deftest
  (test "parse-body"
    (= {:hello "world"} (http/parse-body "hello=world")))

  (test "parse-body with escaped char"
    (= {:hello "world" :email "janet@example.com"} (http/parse-body "hello=world&email=janet%40example.com"))))


(deftest
  (test "cookie-string"
    (= "name=value; "
       (http/cookie-string "name" "value" {})))

  (test "cookie-string with samesite"
    (= "name=value; SameSite=strict"
       (http/cookie-string "name" "value" {"SameSite" "strict"})))

  (test "cookie-string with samesite and httponly"
    (= "name=value; SameSite=strict"
       (http/cookie-string "name" "value" {"SameSite" "strict" "HttpOnly" nil}))))


(deftest
  (test "parse-query-string with nil"
    (nil? (http/parse-query-string nil)))

  (test "parse-query-string with blank"
    (nil? (http/parse-query-string "")))

  (test "parse-query-string with a ? only"
    (nil? (http/parse-query-string "?")))

  (test "parse-query-string with a url without a ?"
    (nil? (freeze
           (http/parse-query-string "/hello-world/part/part1"))))

  (test "parse-query-string with a real query string"
    (= {:a "b" :c "2" :encoded "hello world"}
       (freeze
        (http/parse-query-string "/hello-world/part/part1?a=b&c=2&encoded=hello%20world")))))
