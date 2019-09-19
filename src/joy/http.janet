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


(def- escape-chars
  {"%20" " " "%3C" "<" "%3E" ">" "%23" `#` "%25" "%"
   "%7B" "{" "%7D" "}" "%7C" "|" "%5C" `\` "%5E" "^"
   "%7E" "~" "%5B" "[" "%5D" "]" "%60" "`" "%3B" ";"
   "%2F" "/" "%3F" "?" "%3A" ":" "%40" "@" "%3D" "="
   "%26" "&" "%24" "$" "%2B" "+" "+" " " "%27" "'"})


(defn- substitute [patt subst] ~(/ (<- ,patt) ,subst))


(defn- substitutes [patts]
  (peg/compile ['% ['any ['+ ;patts '(<- 1)]]]))


(def- decode-substitution
  (substitutes
    (seq [[patt subst] :pairs escape-chars]
         (substitute patt subst))))


(defn decode-string
  "Decodes string from query string"
  [s]
  (unless s (break))
  (first (peg/match decode-substitution s)))


(def- encode-substitution
  (substitutes
    (seq [[subst patt] :pairs escape-chars]
         (substitute patt subst))))


(defn encode-string
  "Encodes string to query string"
  [s]
  (unless s (break))
  (first (peg/match encode-substitution s)))


(defn parse-body [string-s]
  (when (string? string-s)
    (->> (string/split "&" string-s)
         (map (fn [val] (string/split "=" val)))
         (flatten)
         (apply table)
         (helper/map-keys keyword)
         (helper/map-vals decode-string))))
