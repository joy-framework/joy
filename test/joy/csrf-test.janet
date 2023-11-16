(import tester :prefix "" :exit true)
(import ../../src/joy :prefix "")


(deftest
  (let [token @"\xCC\\\xF0Y5|38\x9E\xD9\x05<\x06\x99\xE3=\xE3\xD9\x9Ch\xFD3@?\x98\x11\xC6b\x96\"\xCB\xF2"
        masked-token "aaaa8e1fa88cdd067b8a776058e53be1041d3ff33362b73705ca28dcaf56a35966f67e469df0ee3ee553725c5e7cd8dce7c4a39bce51f7089ddbeebe397468ab"
        handler-response @{:status 200 :body "" :headers {"Content-Type" "text/html"}}]
    (test "token from multipart request"
        (let [middleware-request @{:method :post :uri "/save" :headers {"Content-Type" "multipart/form-data"} :csrf-token token :multipart-body @[{:name "test" :filename "test.txt" :size 36 :content-type "text/plain"} {:name "__csrf-token" :content masked-token}]}
              middleware-response ((csrf-token (fn [request]
                                                 (->> (get request :masked-token)
                                                      (put handler-response :test-request-masked-token)))) middleware-request)]
          (and (= 200 (get middleware-response :status))
               (= token (get middleware-response :csrf-token))
               (truthy? (get middleware-response :test-request-masked-token)))))

    (test "token from form request"
          (let [middleware-request @{:method :post :uri "/save" :headers {"Content-Type" "application/x-www-form-urlencoded"} :csrf-token token :body {:some "thing" :__csrf-token masked-token}}
                middleware-response ((csrf-token (fn [request]
                                                   (->> (get request :masked-token)
                                                        (put handler-response :test-request-masked-token)))) middleware-request)]
            (and (= 200 (get middleware-response :status))
                 (= token (get middleware-response :csrf-token))
                 (truthy? (get middleware-response :test-request-masked-token)))))

    (test "token from request with header"
          (let [middleware-request @{:method :post :uri "/save" :headers {"Content-Type" "application/json" "X-CSRF-Token" masked-token} :csrf-token token :body {:some "thing"}}
                middleware-response ((csrf-token (fn [request]
                                                   (->> (get request :masked-token)
                                                        (put handler-response :test-request-masked-token)))) middleware-request)]
            (and (= 200 (get middleware-response :status))
                 (= token (get middleware-response :csrf-token))
                 (truthy? (get middleware-response :test-request-masked-token)))))))
