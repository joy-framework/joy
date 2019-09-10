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
