(defn kebab-case [val]
  (string/replace-all "_" "-" val))


(defn snake-case [val]
  (string/replace-all "-" "_" val))


(defn map-keys [f struct-m]
  (let [acc @{}]
    (loop [[k v] :in (pairs struct-m)]
      (put acc (f k) v))
    (table/to-struct acc)))


(defn map-vals [f struct-m]
  (let [acc @{}]
    (loop [[k v] :in (pairs struct-m)]
      (put acc k (f v)))
    (table/to-struct acc)))


(defn get-in [dictionary-m indexed-keys]
  (when (and (dictionary? dictionary-m)
          (indexed? indexed-keys))
    (let [val (get dictionary-m (first indexed-keys))
          indexed-keys (drop 1 indexed-keys)]
      (if (empty? indexed-keys)
        val
        (get-in val indexed-keys)))))


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


(defmacro rescue [& body]
  ~(try
     [nil ,(splice body)]
     ([err] [err nil])))
