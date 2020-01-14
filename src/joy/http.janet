(import ./helper :as helper)
(import uri)


(def url-decode uri/unescape)


(def url-encode uri/escape)


(defn parse-body [string-s]
  (when (and (string? string-s)
          (not (empty? string-s)))
    (->> (string/split "&" string-s)
         (map |(string/split "=" $))
         (flatten)
         (apply table)
         (helper/map-keys keyword)
         (helper/map-vals uri/unescape))))


(defn cookie-pair [str]
  (let [[k v] (string/split "=" str)]
    (if (nil? v)
      [k true]
      [k v])))


(defn cookie-string [name value options]
  (string name "=" value `; `
    (string/join
      (map (fn [[k v]]
             (if (empty? v)
               (string k)
               (string k "=" v)))
        (pairs options))
      "; ")))


(defn parse-cookie [str]
  (if (and (string? str)
        (not (empty? str)))
    (->> (string/split ";" str)
         (map string/trim)
         (filter |(not (empty? $)))
         (map cookie-pair)
         (flatten)
         (apply table))
    @{}))


(defn parse-query-string [str]
  (when (string? str)
    (when-let [parsed (get (uri/parse str) :query)]
      (helper/map-keys keyword parsed))))

