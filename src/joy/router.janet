(import ./helper :prefix "")


(defn route-url [string-route struct-params]
  (var mut-string-route string-route)
  (loop [[k v] :in (pairs struct-params)]
    (set mut-string-route (string/replace k v mut-string-route)))
  mut-string-route)


(defn route-matches? [array-route1 dictionary-request]
  (let [[route-method route-url] array-route1
        {:method method
         :uri uri} dictionary-request]
    (true? (and (= method route-method)
             (= route-url uri)))))


(defn route-params [string-route-url string-request-url]
  (let [route-url-segments (string/split "/" string-route-url)
        request-url-segments (string/split "/" string-request-url)]
    (if (= (length route-url-segments)
          (length request-url-segments))
      (as-> (interleave route-url-segments request-url-segments) %
            (apply struct %)
            (select-keys % (filter (fn [x] (string/has-prefix? ":" x)) route-url-segments)))
      {})))


(defn find-route [indexed-routes dictionary-request]
  (let [{:uri uri :method method} dictionary-request]
    (first
      (filter (fn [indexed-route]
                (let [[method url handler] indexed-route
                      url (route-url url
                            (route-params url uri))
                      indexed-route [method url handler]]
                  (route-matches? indexed-route dictionary-request)))
        indexed-routes))))


(defn handler
  "Creates a handler from routes"
  [routes]
  (fn [request]
    (let [{:uri uri} request
          route (find-route routes request)
          [route-method route-uri route-fn] route
          route-params (route-params route-uri uri)
          request (merge request {:params (map-keys (fn [val] (-> (string/replace ":" "" val) (keyword))) route-params)})]
      (when (function? route-fn)
        (route-fn request)))))
