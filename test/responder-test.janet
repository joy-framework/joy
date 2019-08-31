(import tester :prefix "" :exit true)
(import "src/joy/responder" :as responder)

(deftest
  (test "get responder"
    (= {:status 200
        :body "response"
        :headers {"Content-Type" "text/plain"}}
       (responder/respond :text "response")))

  (test "404"
    (= {:status 404
        :body "response"
        :headers {"Content-Type" "text/plain"}}
       (responder/respond :text "response"
          :status 404)))

  (test "json"
    (= {:status 200
        :body {:a 1}
        :headers {"Content-Type" "application/json"}}
       (responder/respond :json {:a 1}))))
