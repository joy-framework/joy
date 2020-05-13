(import ./helper :prefix "")
(import ./http :as http)

(varglobal '*route-table* @{})


(defn- route-param? [val]
  (string/has-prefix? ":" val))


(defn- route-param [val]
  (if (route-param? val)
    val
    (string ":" val)))


(defn- route-url [string-route struct-params]
  (var mut-string-route string-route)
  (loop [[k v] :in (pairs struct-params)]
    (set mut-string-route (string/replace (route-param k) (string v) mut-string-route)))
  mut-string-route)


(defn- route-params [app-url uri]
  (let [app-parts (string/split "/" app-url)
        req-parts (string/split "/" uri)]
    (as-> (interleave app-parts req-parts) ?
          (partition 2 ?)
          (filter (fn [[x y]] (route-param? x)) ?)
          (map (fn [[x y]] @[(keyword (drop 1 x)) y]) ?)
          (mapcat identity ?)
          (table ;?))))


(defn- wildcard-params [patt uri]
  (def parts (string/split "*" patt))
  (def arr (interpose '(<- (some (if-not "\0" 1))) parts))
  (def p (freeze (array/insert arr 0 '*)))
  (first (peg/match p uri)))


(defn- part? [[s1 s2]]
  (or (= s1 s2)
      (string/find ":" s1)))


(defn- route? [app-route request]
  (let [[app-method app-url] app-route
        {:uri uri :method method} request
        app-parts (string/split "/" app-url)
        req-parts (string/split "/" uri)]
    (and (= (string/ascii-lower method)
            (string/ascii-lower app-method))
         (or (= app-url uri)
             (and (string/has-suffix? "*" app-url)
                  (string/has-prefix? (string/trimr app-url "*") uri))
             (and (= (length app-parts) (length req-parts))
                  (string/find ":" app-url)
                  (= (length app-parts)
                     (as-> (interleave app-parts req-parts) ?
                           (partition 2 ?)
                           (filter part? ?)
                           (length ?))))))))


(defn- find-route [routes request]
  (first (filter |(route? $ request) routes)))


(defn- route-name [route]
  (-> route last keyword))


(defn- route-table [routes]
  (->> routes
       (mapcat |(tuple (route-name $) $))
       (apply table)))


(defn handler
  "Creates a handler function from routes. Returns nil when handler/route doesn't exist."
  [routes]
  (fn [request]
    (let [{:uri uri} request
          route (find-route routes request)
          [route-method route-uri route-fn] route
          wildcard (wildcard-params route-uri uri)
          params (route-params route-uri uri)
          request (merge request {:params params :wildcard wildcard})]
      (when (function? route-fn)
        (route-fn request)))))


(defn app [& handlers]
  (fn [request]
    (some |($ request) handlers)))


(defmacro routes [& args]
  (do
    ~(set *route-table* (merge *route-table* (route-table ,;args)))))


(defn present? [val]
  (and (truthy? val)
       (not (empty? val))))


(defn namespace [val]
  (when (keyword? val)
    (let [arr (string/split "/" val)
          len (dec (length arr))
          ns-array (array/slice arr 0 len)]
      (string/join ns-array "/"))))


(defmacro defroutes [& args]
  (let [name (first args)
        rest (drop 1 args)
        rest (map |(array ;$) rest)

        # get the "namespaces" of the functions
        files (as-> rest ?
                    (map |(get $ 2) ?)
                    (map namespace ?)
                    (filter present? ?)
                    (distinct ?))

        # import all distinct file names from routes
        _ (loop [file :in files]
            (try
              (import* (string "./routes/" file) :as file)
              ([err]
               (print (string "Route file src/routes/" file ".janet does not exist.")))))

        rest (map |(update $ 2 symbol) rest)]

    (routes rest)
    ~(def ,name :public ,rest)))


(defn- query-string [m]
  (when (dictionary? m)
    (let [s (->> (pairs m)
                 (map (fn [[k v]] (string (-> k string http/url-encode) "=" (http/url-encode v))))
                 (join-string "&"))]
      (when (not (empty? s))
        (string "?" s)))))


(defn url-for [route-keyword &opt params]
  (default params {})
  (let [route (get *route-table* route-keyword)
        _ (when (nil? route) (error (string "Route " route-keyword " does not exist")))
        route-params (->> (kvs params)
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
  (let [[method url] (get *route-table* route-keyword)
        action (route-url url params)
        _method (when (not= :post method) method)
        method (if (not= :get method) :post :get)]
    {:method method
     :_method _method
     :action action}))


(defn redirect-to [route-keyword &opt params]
  @{:status 302
    :body " "
    :headers @{"Location" (url-for route-keyword (or params {}))}})
