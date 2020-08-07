(import ./helper :prefix "")
(import ./http :as http)
(import ./middleware :prefix "")
(import ./logger :prefix "")
(import ./csrf :prefix "")

(varglobal '*routes* @[])
(varglobal '*route-table* @{})
(varglobal '*before-filters* @[])
(varglobal '*after-filters* @[])

(def- parts '(some (* "/" '(any (+ :a :d (set ":%$-_.+!*'(),"))))))

(defn- route-param? [val]
  (string/has-prefix? ":" val))


(defn- route-param [val]
  (if (route-param? val)
    val
    (string ":" val)))


(defn- route-url [string-route struct-params]
  (var mut-string-route string-route)
  (loop [[k v] :in (pairs struct-params)]
    (set mut-string-route (string/replace (route-param k) (string v) mut-string-route))
    (when (and (= k :*)
               (indexed? v))
      (loop [wc* :in v]
        (set mut-string-route (string/replace "*" (string wc*) mut-string-route)))))
  mut-string-route)


(defn- route-params [app-url uri]
  (let [app-parts (string/split "/" app-url)
        req-parts (string/split "/" uri)]
    (as-> (interleave app-parts req-parts) ?
          (partition 2 ?)
          (filter (fn [[x y]] (route-param? x)) ?)
          (map (fn [[x y]] @[(keyword (drop 1 x)) (first (string/split "?" y))]) ?)
          (mapcat identity ?)
          (table ;?))))


(defn- slash-suffix [p]
  (if (keyword? (last p))
    (put p (dec (length p)) :slash-param)
    p))


(defn- wildcard-params [patt uri]
  (let [p (->> (string/split "*" patt)
               (interpose :param)
               (filter |(not (empty? $)))
               (slash-suffix)
               (freeze))

        route-peg ~{:param (<- (some (+ :w (set "%$-_.+!*'(),"))))
                    :slash-param (<- (some (+ :w (set "%$-_.+!*'(),/"))))
                    :main (* ,;p)}]

    (or (peg/match route-peg uri)
        @[])))


(defn- part? [[s1 s2]]
  (or (= s1 s2)
      (string/find ":" s1)))


(defn- route? [app-route request]
  (let [[route-method route-url] app-route
        {:uri uri :method method} request
        uri (first (string/split "?" uri))]

         # check methods match first
    (and (= (string/ascii-lower method)
            (string/ascii-lower route-method))

             # check that the url isn't an exact match
         (or (= route-url uri)

             # check for urls with params
             (let [uri-parts (peg/match parts uri)
                   route-parts (peg/match parts route-url)]

               # 1. same length
               # 2. the route definition has a semicolon in it
               # 3. the length of the parts are equal after
               #    accounting for params
               (and (= (length route-parts) (length uri-parts))
                    (string/find ":" route-url)
                    (= (length route-parts)
                       (as-> (interleave route-parts uri-parts) ?
                             (partition 2 ?)
                             (filter part? ?)
                             (length ?)))))

             # wildcard params (still a work in progress)
             (and (string/find "*" route-url)
                  (let [idx (string/find "*" route-url)
                        sub (string/slice route-url 0 idx)]
                     (string/has-prefix? sub uri)))))))


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
    (when-let [route (find-route routes request)
               [route-method route-uri route-fn] route
               wildcard (wildcard-params route-uri (request :uri))
               params (route-params route-uri (request :uri))
               request (merge request {:params (or params @{}) :wildcard wildcard})
               f (if (function? route-fn)
                   route-fn
                   (eval (symbol route-fn)))]
      (when f
        (f request)))))


(defn handlers [& handler-fns]
  (fn [request]
    (some |($ request) handler-fns)))


(defn- method [str]
  (def part (last (string/split "/" str)))
  (keyword
    (or (find |(= $ part) ["post" "put" "patch" "delete" "head" "trace"])
        "get")))


(defn- to-route [str]
  [(method str) (string str) (eval str) (string str)])


(defn resolve-route [[method url handler alias]]
  (def handler (if (function? handler)
                 handler
                 (eval (symbol handler))))

  (if alias
    [method url handler alias]
    [method url handler]))


(defn- auto-routes []
  (def bindings (filter |(string/has-prefix? "/" $) (all-bindings (fiber/getenv (fiber/current)) true)))
  # move wildcard routes to back
  (def not-wildcards (filter |(not (string/has-suffix? "*" $)) bindings))
  (def wildcards (filter |(string/has-suffix? "*" $) bindings))
  (def bindings (array/concat not-wildcards wildcards))
  (def function-routes (map to-route bindings))
  (set *route-table* (merge *route-table* (route-table function-routes)))
  (if (empty? function-routes)
    (map resolve-route *routes*)
    function-routes))


(defn- resolve-filter [[url sym]]
  [url (eval sym)])


(defn with-before-middleware [handler]
  (let [before-filters (map resolve-filter *before-filters*)]
    (fn [request]
      (var req request)
      (loop [[url fn-name] :in before-filters]
        (def params* (wildcard-params url (request :uri)))
        (when (any? params*)
          (when-let [f (eval fn-name)]
            (set req (f req)))))
      (handler req))))


(defn with-after-middleware [handler]
  (let [after-filters (map resolve-filter *after-filters*)]
    (fn [request]
      (var res (handler request))
      (loop [[url fn-name] :in after-filters]
        (def params* (wildcard-params url (request :uri)))
        (when (any? params*)
          (when-let [f (eval fn-name)]
            (set res (f request res)))))
      res)))


(defn- wrap-if [options handler k middleware]
  (if (options k)
    (middleware handler)
    handler))


(defn- wrap-with [options handler k middleware]
  (if (options k)
    (middleware handler (options k))
    handler))


(defn app [&opt opts]
  (default opts {})
  (def options {:routes (auto-routes)
                :layout false
                :extra-methods true
                :query-string true
                :body-parser true
                :json-body-parser true
                :logger {}
                :csrf-token true
                :session {}
                :x-headers {}
                :server-error true
                :404 true
                :static-files true})

  (def options (merge options opts))

  (def wrap-if (partial wrap-if options))
  (def wrap-with (partial wrap-with options))

  (-> (handler (options :routes))
      (wrap-with :layout layout)
      (with-before-middleware)
      (with-after-middleware)
      (wrap-if :csrf-token csrf-token)
      (wrap-with :session session)
      (wrap-if :extra-methods extra-methods)
      (wrap-if :query-string query-string)
      (wrap-if :body-parser body-parser)
      (wrap-if :json-body-parser json-body-parser)
      (wrap-if :server-error server-error)
      (wrap-with :x-headers x-headers)
      (wrap-if :static-files static-files)
      (wrap-with :404 not-found)
      (wrap-with :logger logger)))


(defn namespace [val]
  (when (keyword? val)
    (let [arr (string/split "/" val)
          len (dec (length arr))
          ns-array (array/slice arr 0 len)]
      (string/join ns-array "/"))))


(defn route [method url handler-name &opt handler-alias]
  (let [handler (if (function? handler-name)
                  handler-name
                  (symbol handler-name))
        r (if handler-alias
            [method url handler handler-alias]
            [method url handler])]
    (array/push *routes* r)
    (put *route-table* (route-name r) r)
    handler))


(defmacro routes [& args]
  (let [args (map |(array ;$) args)

        # get the "namespaces" of the functions
        files (as-> args ?
                    (map |(get $ 2) ?)
                    (map namespace ?)
                    (filter present? ?)
                    (distinct ?))

        # import all distinct file names from routes
        _ (loop [file :in files]
            (try
              (import* (string "./routes/" file) :as file)
              ([err]
               (print (string "Route file ./routes/" file ".janet does not exist.")))))

        args (map |(update $ 2 symbol) args)]

    (set *route-table* (merge *route-table* (route-table args)))
    args))


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
               (print (string "Route file ./routes/" file ".janet does not exist.")))))

        rest (map |(update $ 2 symbol) rest)]

    (set *route-table* (merge *route-table* (route-table rest)))

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
        _method (when (and (not= :post method)
                           (not= :get method))
                  method)
        method (if (not= :get method) :post :get)]
    {:method method
     :_method _method
     :action action}))


(defn redirect-to [route-keyword &opt params]
  @{:status 302
    :body " "
    :headers @{"Location" (url-for route-keyword (or params {}))}})


(defn before [url fn-name]
  (array/push *before-filters* [url (symbol fn-name)]))


(defn after [url fn-name]
  (array/push *after-filters* [url (symbol fn-name)]))
