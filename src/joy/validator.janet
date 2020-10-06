(import ./helper :prefix "")
(import uri)

(defn- max-length? [len val]
  (> (length val) len))


(defn- min-length? [len val]
  (< (length val) len))


(defn- matches-peg? [peg val]
  (peg/match peg val))


(defn- email? [val]
  (let [result (peg/match '(any (+ (* ($) "@") 1)) val)]
    (and (not (nil? result))
      (not (empty? result)))))


(defn- uri? [val]
  (when (string? val)
    (->> (uri/parse val)
         (contains? :path))))


(defn- invalid-keys [ks dict pred]
  (filter |(pred (get dict $))
    ks))


(defn- error-map [ks message]
  (->> (map (fn [k] {k (string k " " message)}) ks)
       (apply merge)))


(defn validates
  `Takes a keyword or a list of keywords and validator key-value pairs and returns a dictionary
   in the form of {:keys [:a] :required true :message ""}`
  [key-or-keys & args]
  (let [opts (apply table args)
        ks (if (indexed? key-or-keys) key-or-keys [key-or-keys])]
    (merge {:keys ks} opts)))


(defn validate [validator body &opt raise?]
  (default raise? true)

  (let [{:keys ks
         :required required
         :message message
         :min-length min-length
         :max-length max-length
         :email email
         :matches matches
         :uri uri} validator
        msg (cond
              (true? required) "is required"
              (number? min-length) (string "needs to be more than " min-length " characters")
              (number? max-length) (string "needs to be less than " max-length " characters")
              (not (nil? email)) "needs to be an email"
              (not (nil? matches)) (string "needs to match " (string/format "%q" matches))
              (not (nil? uri)) (string "needs to be a valid uri " (string/format "%q" uri))
              :else "")
        predicate (cond
                    (true? required) blank?
                    (number? min-length) (partial min-length? min-length)
                    (number? max-length) (partial max-length? max-length)
                    (not (nil? email)) (comp not email?)
                    (not (nil? matches)) (partial (comp not matches-peg?) matches)
                    (not (nil? uri)) (comp not uri?)
                    :else identity)]
    (let [invalid-ks (invalid-keys ks body predicate)]
      (if (empty? invalid-ks)
        body
        (if raise?
          (-> (error-map invalid-ks (or message msg))
              (raise :params))
          (merge body {:errors (error-map invalid-ks (or message msg))}))))))


(defn permit
  `Takes a list of keywords and returns a dictionary: {:keys [:a :b :c] :permits true}`
  [& args]
  (if (and (one? (length args))
           (indexed? (first args)))
    {:keys (first args) :permit true}
    {:keys args :permit true}))


(defn params
  `Takes a table name and a list of validator dictionaries
   and returns a function that either raises an error or returns the body

   Example:

   (def params
     (params :accounts
       (validates [:name :real-name] :required true)
       (permit [:name :real-name])))

   =>

   (params {:name "hello"}) # error: real-name is required
   (params {:name "hello" :real-name "real"}) => {:name "hello" :real-name "real" :db/table :accounts}`
  [t & args]
  (fn [{:body body}]

    (->> (filter |(nil? (get $ :permit)) args)
         (map |(validate $ body))) # this raises if the validator isn't met

    (let [allowed-keys (-> (filter |(true? (get $ :permit)) args)
                           (get-in [0 :keys]))]
      (if (or (nil? allowed-keys)
              (empty? allowed-keys))
        (merge body {:db/table t})
        (merge (table/slice body allowed-keys)
               {:db/table t})))))


(defn body
  `Takes a table name and a list of validator dictionaries
   and returns the validator dictionaries as map

   Example:

   (def accounts/body
     (body :accounts
       (validates [:name :real-name] :required true)
       (permit [:name :real-name])))

   =>

   (accounts/body {:name "hello"}) # {... :db/errors {:real-name "real-name is required"}}
   (accounts/body {:name "hello" :real-name "real"}) => {:name "hello" :real-name "real" :db/table :accounts}`
  [t & args]
  (fn [request]
    (let [bdy (get request :body @{})
          {:errors errors} (->> (filter |(nil? (get $ :permit)) args)
                                (map |(validate $ bdy false))
                                (apply merge))

          allowed-keys (-> (filter |(true? (get $ :permit)) args)
                           (get-in [0 :keys]))]

        (merge (table/slice bdy allowed-keys)
               {:db/table t
                :db/errors errors}))))
