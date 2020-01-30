# helper.janet

(defn kebab-case
  `Changes a string from snake_case to kebab-case

   Example

   (kebab-case "created_at") -> "created-at"`
  [val]
  (string/replace-all "_" "-" val))


(defn snake-case
  `Changes a string from kebab-case to snake_case

   Example

   (snake-case "created-at") -> "created_at"`
  [val]
  (string/replace-all "-" "_" val))


(defn map-keys
  `Executes a function on a dictionary's keys and
   returns a struct

   Example

   (map-keys snake-case {:created_at "" :uploaded_by ""}) -> {:created-at "" :uploaded-by ""}
  `
  [f struct-m]
  (let [acc @{}]
    (loop [[k v] :in (pairs struct-m)]
      (put acc (f k) v))
    (table/to-struct acc)))


(defn map-vals [f struct-m]
  (let [acc @{}]
    (loop [[k v] :in (pairs struct-m)]
      (put acc k (f v)))
    (table/to-struct acc)))


(defn contains?
  `Finds a truthy value in an indexed or a dictionary's
   keys

   Example

   (contains? :a [:a :b :c]) => true
   (contains? :a {:a 1 :b 2 :c 3}) => true
   (contains? :d {:a 1 :b 2 :c 3}) => false`
  [val arr]
  (when (or (indexed? arr)
            (dictionary? arr))
    (truthy?
     (or (find |(= val $) arr)
         (get arr val)))))


(defn select-keys
  `Selects part of a dictionary based on arr of keys
   and returns a table.

   Example

   (select-keys @{:a 1 :b 2 :c 3} [:a :b]) => @{:a 1 :b 2}
   (select-keys @{:a 1 :b 2 :c 3} []) => @{}
   (select-keys @{:a 1 :b 2 :c 3} [:a]) => @{:a 1}`
  [dict arr]
  (if (and (dictionary? dict)
        (indexed? arr))
    (->> (pairs dict)
         (filter |(contains? (first $) arr))
         (mapcat identity)
         (apply table))
    @{}))


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


(defmacro with-file
  `A macro that takes a binding array, ex: [f "some-file.txt"] and a body of forms and executes them in the context of the binding.

   Example:
   (with-file [f "test.txt"]
     (file/read f))`
  [binding & body]
  ~(with [,(first binding) (,file/open ,(get binding 1) ,(get binding 2 :r)) ,file/close]
     ,;body))


(defn file-exists? [filename]
  (try
    (do
      (with-file [f filename])
      true)
    ([err]
     (not= err "bad slot #0, expected core/file, got nil"))))


(defn create-file
  "Creates a new file and calls file/close"
  [filename]
  (with [f (file/open filename :w) file/close]
    (file/write f)))


(defn rand-int [min-int max-int]
  (+ min-int (math/round (* (- max-int min-int) (math/random)))))


(defn rand-nth [arr]
  (get arr (rand-int 0 (dec (length arr)))))


(defn rand-str [len]
  (let [chars (array/concat (range 65 90)
                            (range 97 123)
                            (range 48 57))]
    (string/from-bytes ;(map (fn [_] (rand-nth chars)) (range 0 len)))))


(defn method? [name request]
  (-> (get request :method)
      (string/ascii-upper)
      (= name)))


(def get? (partial method? "GET"))
(def head? (partial method? "HEAD"))
(def post? (partial method? "POST"))
(def put? (partial method? "PUT"))
(def patch? (partial method? "PATCH"))
(def delete? (partial method? "DELETE"))


(defn xhr? [request]
  (= "XMLHttpRequest" (get-in request [:headers "X-Requested-With"])))


(defn body? [request]
  (truthy? (get request :body)))


(def version "0.5.2")


(defn drop-last [val]
  (cond
    (array? val) (array/slice val 0 (dec (length val)))
    (tuple? val) (tuple/slice val 0 (dec (length val)))
    :else @[]))


(defmacro rest
  `Returns all but the first element in an array/tuple.
   Does not maintain input (array or tuple) data structure,
   always returns a tuple. Throws on nil.

   Example

   (rest @[1 2 3]) => (2 3)
   (rest [3 2 1]) => (2 1)`
  [indexed]
  ~(drop 1 ,indexed))
