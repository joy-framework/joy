(import ./helper :as helper)

(defn max-length? [len val]
  (> (length val) len))


(defn min-length? [len val]
  (< (length val) len))


(defn blank? [val]
  (or (nil? val)
    (empty? val)))


(defn matches-peg? [peg val]
  (peg/match peg val))


(defn email? [val]
  (let [result (peg/match '(any (+ (* ($) "@") 1)) val)]
    (and (not (nil? result))
      (not (empty? result)))))


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
         :max-length max-length
         :email email
         :matches matches} validator
        msg (cond
              (true? required) "is required"
              (number? min-length) (string "needs to be more than " min-length " characters")
              (number? max-length) (string "needs to be less than " max-length " characters")
              (not (nil? email)) "needs to be an email"
              (not (nil? matches)) (string "needs to match " (string/format "%q" matches))
              :else "")
        predicate (cond
                    (true? required) blank?
                    (number? min-length) (partial min-length? min-length)
                    (number? max-length) (partial max-length? max-length)
                    (not (nil? email)) (comp not email?)
                    (not (nil? matches)) (partial (comp not matches-peg?) matches)
                    :else identity)]
    (let [invalid-ks (invalid-keys ks body predicate)]
      (if (empty? invalid-ks)
        body
        (helper/raise (error-map invalid-ks (or message msg)))))))


(defn params
  `Takes a list of validator dictionaries
   and returns a function that either raises an error or returns the body`
  [& args]
  (fn [body]
    (map |(validate $ body) args) # this raises if the validator isn't met
    body))
