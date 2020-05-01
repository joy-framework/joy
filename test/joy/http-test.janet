(import tester :prefix "" :exit true)
(import "src/joy" :prefix "")


(deftest
  (test "parse-body"
    (deep= @{:hello "world"} (http/parse-body "hello=world")))

  (test "parse-body with escaped char"
    (deep= @{:hello "world" :email "janet@example.com"} (http/parse-body "hello=world&email=janet%40example.com")))

  (test "parse-body with space char"
    (deep= @{:space-test "this is a test" :email "janet@example.com"} (http/parse-body "space-test=this%20is%20a%20test&email=janet%40example.com")))

  (test "parse-body with + chars"
    (deep= @{:space-test "this is a test " :email "janet@example.com"} (http/parse-body "space-test=this+is+a+test%20&email=janet%40example.com")))

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
       (http/url-encode "hello world!!")))

  (test "multipart?"
    (true? (http/multipart? {:headers {"Content-Type" "multipart/form-data; boundary=------------------------a7d70bee2175f725"}})))

  (test "multipart? false"
    (false? (http/multipart? {:headers {"Content-Type" "application/x-www-form-urlencoded"}})))

  (test "multipart-boundary"
    (= "a simple boundary" (http/multipart-boundary {:headers {"Content-Type" "multipart/form-data; boundary=a simple boundary"}})))

  (test "multipart-boundary 2"
    (= "------------------------a7d70bee2175f725" (http/multipart-boundary {:headers {"Content-Type" "multipart/form-data; boundary=------------------------a7d70bee2175f725"}})))

  (test "multipart header"
    (= {:name "person"
        "Content-Disposition" "form-data; name=\"person\""}
       (http/multipart-header "Content-Disposition: form-data; name=\"person\"")))

  (test "multipart header 2"
    (= {:name "test"
        :filename "testing weird @@ chars !! in ,<,> this one.txt"
        "Content-Disposition" "form-data; name=\"test\" filename=\"testing weird @@ chars !! in ,<,> this one.txt\""}
       (http/multipart-header "Content-Disposition: form-data; name=\"test\" filename=\"testing weird @@ chars !! in ,<,> this one.txt\"")))

  (test "multipart-headers"
    (= {:name "test"
        :filename "test.txt"
        "Content-Disposition" "form-data; name=\"test\"; filename=\"test.txt\""
        "Content-Type" "text/plain"}
       (http/multipart-headers "Content-Disposition: form-data; name=\"test\"; filename=\"test.txt\"\r\nContent-Type: text/plain\r\n\r\nthis is a test\n\nwith two lines in it\n\r\n")))

  (test "parse-multipart-body"
    (deep= @[{:name "person" :content "anonymous"}
             {:name "test" :filename "test.txt" :size 36 :content-type "text/plain"}]
           (let [sample-body "--------------------------78eaa4a42a0548dd\r\nContent-Disposition: form-data; name=\"person\"\r\n\r\nanonymous\r\n--------------------------78eaa4a42a0548dd\r\nContent-Disposition: form-data; name=\"test\"; filename=\"test.txt\"\r\nContent-Type: text/plain\r\n\r\nthis is a test\n\nwith two lines in it\n\r\n--------------------------78eaa4a42a0548dd--\r\n"
                 request {:headers {"Content-Type" "multipart/form-data; boundary=------------------------78eaa4a42a0548dd"}
                          :body sample-body}]
             (as-> (http/parse-multipart-body request) ?
                   (map |(struct :name (get $ :name)
                                 :content (get $ :content)
                                 :filename (get $ :filename)
                                 :size (get $ :size)
                                 :content-type (get $ :content-type))
                        ?))))))
