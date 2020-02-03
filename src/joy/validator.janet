(import ./helper :as helper)
(import uri)

(defn- max-length? [len val]
  (> (length val) len))


(defn- min-length? [len val]
  (< (length val) len))


(defn- blank? [val]
  (or (nil? val)
    (empty? val)))


(defn- matches-peg? [peg val]
  (peg/match peg val))


(defn- email? [val]
  (let [result (peg/match '(any (+ (* ($) "@") 1)) val)]
    (and (not (nil? result))
      (not (empty? result)))))


(defn- uri? [val]
  (when (string? val)
    (->> (uri/parse val)
         (helper/contains? :path))))


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


(defn validate [validator body]
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
        (-> (error-map invalid-ks (or message msg))
            (helper/raise :params))))))


(defn permit
  `Takes a list of keywords and returns a dictionary: {:keys [:a :b :c] :permits true}`
  [key-or-keys]
  (let [ks (if (indexed? key-or-keys) key-or-keys [key-or-keys])]
    {:keys ks :permit true}))


(defn params
  `Takes a list of validator dictionaries
   and returns a function that either raises an error or returns the body`
  [& args]
  (fn [{:body body}]
    (->> (filter |(nil? (get $ :permit)) args)
         (map |(validate $ body))) # this raises if the validator isn't met
    (let [allowed-keys (-> (filter |(true? (get $ :permit)) args)
                           (get-in [0 :keys]))]
      (if (or (nil? allowed-keys)
            (empty? allowed-keys))
        body
        (helper/select-keys body allowed-keys)))))
