(import ./helper :as helper)


(defn cookie-string [name value options]
  (string name "=" value `; `
    (string/join
      (map (fn [[k v]]
             (if (empty? v)
               (string k)
               (string k "=" v)))
        (pairs options))
      "; ")))


(defn ascii->hex
  `Changes a % hex string to \x encoded hex.
  Ex. %F0 -> \xF0`
  [str]
  (let [mapping {"A" 10 "B" 11 "C" 12 "D" 13 "E" 14 "F" 15}
        arr (partition 1 (drop 1 str))
        [a b] (map |(get mapping (string/ascii-upper $) (scan-number $)) arr)
        output (+ b (* a 16))]
    (string/from-bytes output)))


(defn replacer
 "Creates a peg that replaces instances of patt with subst."
 [patt subst]
 (peg/compile ~(% (any (+ (/ (<- ,patt) ,subst) (<- 1))))))


(def encoded-hex-grammar
  ~{:hex (range "09" "af" "AF")
    :main (* "%" :hex :hex)})


(def url-encode-map {"%21" "!" "%23" "#" "%24" "$" "%25" "%"
                     "%26" "&" "%27" "'" "%28" "(" "%29" ")"
                     "%2A" "*" "%2B" "+" "%2C" "," "%2F" "/"
                     "%3A" ":" "%3B" ";" "$3D" "=" "%3F" "?"
                     "%40" "@" "%5B" "[" "%5D" "]"})


(defn url-decode
  "Decodes a string with percent encoding"
  [str]
  (let [encoded-hex? (replacer encoded-hex-grammar ascii->hex)
        url-encoded? (replacer "+" " ")]
    (->> (peg/match url-encoded? str)
         (string/join)
         (peg/match encoded-hex?)
         (string/join))))


(defn url-encode-char [str]
  (-> (invert url-encode-map) (get str str)))


(defn url-encode
  "Encodes a string with percent encoding"
  [str]
  (->> (partition 1 str)
       (map url-encode-char)
       (string/join)))


(defn parse-body [string-s]
  (when (and (string? string-s)
          (not (empty? string-s)))
    (->> (string/split "&" string-s)
         (map |(string/split "=" $))
         (flatten)
         (apply table)
         (helper/map-keys keyword)
         (helper/map-vals url-decode))))


(defn cookie-pair [str]
  (let [[k v] (string/split "=" str)]
    (if (nil? v)
      [k true]
      [k v])))


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


(defn parse-query-string [string-s]
  (when (and (string? string-s)
          (not (nil? (string/find "?" string-s))))
    (->> (string/split "?" string-s)
         (last)
         (parse-body))))

