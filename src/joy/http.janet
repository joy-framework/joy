(import ./helper :as helper)
(import uri)

(def url-decode uri/unescape)
(def url-encode uri/escape)

(defn parse-body [str]
  (as-> str ?
        (string/split "+" ?)
        (string/join ? "%20")
        (uri/parse-query ?)
        (helper/map-keys keyword ?)))


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


(defn multipart? [request]
  (let [content-type (get-in request [:headers "Content-Type"])]
    (string/has-prefix? "multipart/form-data" content-type)))


(defn multipart-boundary [request]
  (when-let [content-type (get-in request [:headers "Content-Type"])
             index (string/find "boundary=" content-type)
             slice-index (+ index (length "boundary="))]
    (string/slice content-type slice-index)))


(def key-value '{:key (some (range "az" "AZ"))
                 :value (any (choice (range "az" "AZ" "09") (set " -_.@!#$%^&*()=~+{}[]|\\/>`<`?',\r\n\t\0")))
                 :main (sequence (<- :key) "=\"" (<- :value) "\"")})

(defn capture [str]
  (peg/compile ~(any (+ (* ,str) 1))))


(defn multipart-header [header-line]
  (let [[header-name header-value] (string/split ": " header-line)
        parts-kvs (peg/match (capture key-value) header-line)
        parts-table (table ;parts-kvs)]
    {header-name header-value
     :name (get parts-table "name")
     :filename (get parts-table "filename")}))


(defn multipart-headers [part]
  (let [index (string/find "\r\n\r\n" part)
        str (string/slice part 0 index)
        header-lines (string/split "\r\n" str)]
    (table/to-struct (apply merge (map multipart-header header-lines)))))


(defn multipart-body [part]
  (let [index (string/find "\r\n\r\n" part)
        start (+ index 4)]
    (as-> (string/slice part start) ?
          (string/trimr ? "\r\n"))))


(defn multipart [part]
  (let [headers (multipart-headers part)
        body (multipart-body part)]
    {:headers headers
     :body body}))


(defn save-part [{:headers headers :body body}]
  (let [name (get headers :name)
        filename (get headers :filename)
        content-type (get headers "Content-Type")
        temp-file (when (truthy? filename) (file/temp))
        content (when (nil? temp-file) body)
        size (when (truthy? temp-file)
               (length body))
        _ (when (truthy? temp-file)
            (file/write temp-file body))]
     (when (truthy? temp-file)
       (file/seek temp-file :set))
     {:filename filename
      :name name
      :content-type content-type
      :temp-file temp-file
      :content content
      :size size}))


(defn parse-multipart-body [request]
  (let [boundary (multipart-boundary request)
        splitter (string "--" boundary "\r\n")
        body (as-> (get request :body) ?
                   (string/trimr ? (string boundary "--\r\n")))]
    (as-> (string/split splitter body) ?
          (filter |(not (empty? $)) ?)
          (map multipart ?)
          (map save-part ?))))
