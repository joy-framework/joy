(import "src/joy/helper" :as helper)


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
  (let [mapping {"0" 0 "1" 1
                 "2" 2 "3" 3
                 "4" 4 "5" 5
                 "6" 6 "7" 7
                 "8" 8 "9" 9
                 "A" 10 "B" 11
                 "C" 12 "D" 13
                 "E" 14 "F" 15}]
    (let [arr (map string/from-bytes (string/bytes (drop 1 str)))
          a (get mapping (get arr 0))
          b (get mapping (get arr 1))
          output (+ b (* a 16))]
      (string/from-bytes output))))


(defn replacer
 "Creates a peg that replaces instances of patt with subst."
 [patt subst]
 (peg/compile ~(% (any (+ (/ (<- ,patt) ,subst) (<- 1))))))


(def encoded-hex-grammar
  ~{:hex (range "09" "af" "AF")
    :main (* "%" :hex :hex)})


(defn escape-hex
  `Changes any % encoded hex in a string to \x encoded hex`
  [s]
  (let [encoded-hex? (replacer encoded-hex-grammar ascii->hex)]
    (string/join
      (peg/match encoded-hex? s)
      "")))


(defn parse-body [string-s]
  (when (string? string-s)
    (->> (string/split "&" string-s)
         (map (fn [val] (string/split "=" val)))
         (flatten)
         (apply table)
         (helper/map-keys keyword)
         (helper/map-vals escape-hex))))
