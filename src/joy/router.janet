# router.janet

(import ./helper :prefix "")


(var route-table @{})


(defn route-param [val]
  (if (and (string? val)
        (string/has-prefix? ":" val))
    val
    (string ":" val)))


(defn route-url [string-route struct-params]
  (var mut-string-route string-route)
  (loop [[k v] :in (pairs struct-params)]
    (set mut-string-route (string/replace (route-param k) (string v) mut-string-route)))
  mut-string-route)


(defn route-matches? [array-route1 dictionary-request]
  (let [[route-method route-url] array-route1
        {:method method :uri uri} dictionary-request
        url (first (string/split "?" uri))]
    (true? (and (= (string/ascii-lower method) (string/ascii-lower route-method))
             (= route-url url)))))


(defn route-params [string-route-url string-request-url]
  (if (true?
       (and (string? string-route-url)
         (string? string-request-url)))
    (let [route-url-segments (string/split "/" string-route-url)
          request-url-segments (string/split "/" string-request-url)]
      (if (= (length route-url-segments)
            (length request-url-segments))
        (as-> (interleave route-url-segments request-url-segments) %
              (apply struct %)
              (select-keys % (filter (fn [x] (string/has-prefix? ":" x)) route-url-segments)))
        {}))
    {}))


(defn find-route [indexed-routes dictionary-request]
  (let [{:uri uri :method method} dictionary-request]
    (or (get
          (filter (fn [indexed-route]
                    (let [[method url handler] indexed-route
                          url (route-url url
                                (route-params url uri))
                          indexed-route [method url handler]]
                      (route-matches? indexed-route dictionary-request)))
            indexed-routes) 0)
        [])))


(defn handler
  "Creates a handler from routes"
  [routes]
  (fn [request]
    (let [{:uri uri} request
          route (find-route routes request)
          [route-method route-uri route-fn] route
          route-params (route-params route-uri uri)
          request (merge request {:params (map-keys (fn [val] (-> (string/replace ":" "" val) (keyword))) route-params)})]
      (if (function? route-fn)
        (route-fn request)
        @{:status 404}))))


(defn depth [val idx]
  (if (indexed? val)
    (depth (first val) (inc idx))
    idx))


(defn flatten-wrapped-routes [x]
  (if (> (depth x 0) 1)
    (mapcat flatten-wrapped-routes x)
    [x]))


(defn middleware [& args]
  (let [middleware-fns (filter function? args)
        routes (filter indexed? args)
        middleware-fn (apply comp middleware-fns)]
    (map (fn [[method url handler]]
           [method url (middleware-fn handler)])
      routes)))


(defn handler-name [func]
  (->> (string func)
       (string/replace "<function " "")
       (string/replace ">" "")))


(defn route-name [route]
  (or (get route 3)
   (-> (get route 2)
       (handler-name)
       (keyword))))


(defn routes [& args]
  (let [flat-routes (flatten-wrapped-routes args)
        route-map (->> flat-routes
                       (mapcat |(tuple (route-name $) $))
                       (apply table))]
    (set route-table (merge route-table route-map))
    flat-routes))


(def url-encode identity)


(defn query-string [m]
  (when (dictionary? m)
    (let [s (->> (pairs m)
                 (map (fn [[k v]] (string (-> k string url-encode) "=" (url-encode v))))
                 (join-string "&"))]
      (when (not (empty? s))
        (string "?" s)))))


(defn url-for [route-keyword &opt params]
  (default params {})
  (let [route (get route-table route-keyword)
        _ (when (nil? route) (error (string "Route " route-keyword " does not exist")))
        route-params (->> (pairs params)
                          (mapcat identity)
                          (apply table))
        route-params (-> (put route-params :? nil)
                         (put "#" nil))
        url (route-url (get route 1) route-params)
        query-params (get params :?)
        qs (or (query-string query-params) "")
        anchor (get params "#")
        anchor (if (not (nil? anchor)) (string "#" anchor) "")]
    (string url qs anchor)))


(defn action-for [route-keyword &opt params]
  (default params {})
  (let [[method url] (get route-table route-keyword)
        action (route-url url params)
        _method method
        method (if (not= :get method) :post :get)]
    {:method method
     :_method _method
     :action action}))


(defn redirect-to [route-keyword &opt params]
  @{:status 302
    :body ""
    :headers {"Location" (url-for route-keyword (or params {}))}})
