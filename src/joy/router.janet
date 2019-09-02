(defn select-keys [struct-map tuple-keys]
  (if (and (dictionary? struct-map)
        (indexed? tuple-keys))
    (do
      (var table-t @{})
      (loop [[k v] :pairs struct-map]
        (when (not (empty? (filter (fn [k1] (= k1 k)) tuple-keys)))
          (put table-t k v)))
      (table/to-struct table-t))
    {}))


(defn map-keys [f struct-m]
  (let [acc @{}]
    (loop [[k v] :in (pairs struct-m)]
      (put acc (f k) v))
    (table/to-struct acc)))


(defn get-in [dictionary-m indexed-keys]
  (when (and (dictionary? dictionary-m)
          (indexed? indexed-keys))
    (let [val (get dictionary-m (first indexed-keys))
          indexed-keys (drop 1 indexed-keys)]
      (if (empty? indexed-keys)
        val
        (get-in val indexed-keys)))))


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


# (route-params "/accounts/:id/hello" "/accounts/1/hello") match
# (route-params "/accounts/:id" "/accounts/1") match
# (route-params "/accounts/show" "/accounts/1") not a match # two segments but no params in route-string
# (route-params "/accounts" "/accounts/1") not a match # two segments

# (find-route routes request)

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
