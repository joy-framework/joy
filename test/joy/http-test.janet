(import tester :prefix "" :exit true)
(import "src/joy/http" :as http)


(deftest
  (test "parse-body"
    (= {:hello "world"} (http/parse-body "hello=world")))

  (test "parse-body with escaped char"
    (= {:hello "world" :email "janet@example.com"} (http/parse-body "hello=world&email=janet%40example.com")))

  (test "parse-body with space char"
    (= {:space-test "this is a test" :email "janet@example.com"} (http/parse-body "space-test=this%20is%20a%20test&email=janet%40example.com")))

  (test "parse-body with + chars"
    (= {:space-test "this is a test " :email "janet@example.com"} (http/parse-body "space-test=this+is+a+test%20&email=janet%40example.com")))

  (test "cookie-string"
    (= "name=value; "
       (http/cookie-string "name" "value" {})))

  (test "cookie-string with samesite"
    (= "name=value; SameSite=strict"
       (http/cookie-string "name" "value" {"SameSite" "strict"})))

  (test "cookie-string with samesite and httponly"
    (= "name=value; SameSite=Strict; HttpOnly"
       (http/cookie-string "name" "value" {"SameSite" "Strict" "HttpOnly" ""})))

  (test "cookie-string with samesite, httponly and path"
    (= "name=value; SameSite=Strict; HttpOnly; Path=/"
       (http/cookie-string "name" "value" {"SameSite" "Strict" "HttpOnly" "" "Path" "/"})))

  (test "parse-query-string with nil"
    (nil? (http/parse-query-string nil)))

  (test "parse-query-string with blank"
    (nil? (http/parse-query-string "")))

  (test "parse-query-string with a ? only"
    (let [parsed (http/parse-query-string "?")]
      (and (empty? parsed)
           (dictionary? parsed))))

  (test "parse-query-string with a url without a ?"
    (nil? (freeze
           (http/parse-query-string "/hello-world/part/part1"))))

  (test "parse-query-string with a real query string"
    (= {:a "b" :c "2" :encoded "hello world"}
       (freeze
        (http/parse-query-string "/hello-world/part/part1?a=b&c=2&encoded=hello%20world"))))

  (test "url encode and decode"
    (= "hello! world!"
       (http/url-decode
        (http/url-encode "hello! world!"))))

  (test "url encode and decode with a + sign"
    (= "hello!+world!"
       (http/url-decode
        (http/url-encode "hello!+world!"))))

  (test "url encode only encodes reserved characters"
    (= "hello%20world%21%21"
       (http/url-encode "hello world!!"))))

