# validator.janet

(defn max-length? [len val]
  (> (length val) len))


(defn min-length? [len val]
  (< (length val) len))


(defn blank? [val]
  (or (nil? val)
    (empty? val)))


(defn invalid-keys [ks dict pred]
  (filter |(pred (get dict $))
    ks))


(defn error-map [ks message]
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
         :max-length max-length} validator
        message (cond
                  (true? required) "is required"
                  (number? min-length) (string "needs to be more than " min-length " characters")
                  (number? max-length) (string "needs to be less than " max-length " characters")
                  :else "")
        predicate (cond
                    (true? required) blank?
                    (number? min-length) (partial min-length? min-length)
                    (number? max-length) (partial max-length? max-length)
                    :else identity)]
    (let [invalid-ks (invalid-keys ks body predicate)]
      (if (empty? invalid-ks)
        body
        (error (error-map invalid-ks message)))
      :else nil)))


(defn params
  `Takes a table name and a list of validator dictionaries
   and returns a function that either raises an error or returns the body`
  [table-name & args]
  (fn [body]
    (map |(validate $ (get body table-name)) args) # this raises if the validator isn't met
    body))
