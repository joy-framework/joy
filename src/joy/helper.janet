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


(defn select-keys [dict ks]
  (if (and (dictionary? dict)
        (indexed? ks))
    (do
      (var new-table @{})
      (loop [k :in ks]
        (put new-table k (get dict k)))
      (if (struct? dict)
        (table/to-struct new-table)
        new-table))
    (if (struct? dict)
      {}
      @{})))


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
