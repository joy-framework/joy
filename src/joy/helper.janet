# helper.janet

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


(defmacro rescue [f &opt id]
  ~(try
     [nil ,f]
     ([err]
      (if (and (dictionary? err)
            (or (true? (get err :id))
              (= ,id (get err :id))))
        [(get err :error) nil]
        (error err)))))


(defn raise [err &opt id]
  (default id true)
  (error {:error err :id id}))


(defn dissoc [struct-map & tuple-keys]
  (if (and (dictionary? struct-map)
        (indexed? tuple-keys))
    (do
      (var table-t (apply table (kvs struct-map)))
      (loop [[k _] :pairs struct-map]
        (put table-t k nil))
      (freeze table-t))
    {}))


(defmacro join-string [sep str]
  ~(string/join ,str ,sep))


(defn pprint [arg]
  (printf "%q\n" arg))
