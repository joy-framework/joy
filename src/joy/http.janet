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


(defn decode-string [s]
  (let [escape-chars {"%20" " " "%3C" "<" "%3E" ">" "%23" `#` "%25" "%"
                      "%7B" "{" "%7D" "}" "%7C" "|" "%5C" `\` "%5E" "^"
                      "%7E" "~" "%5B" "[" "%5D" "]" "%60" "`" "%3B" `;`
                      "%2F" "/" "%3F" "?" "%3A" ":" "%40" "@" "%3D" "="
                      "%26" "&" "%24" "$"}]
    (var output s)
    (loop [[k v] :in (pairs escape-chars)]
      (set output (string/replace-all k v output)))
    output))


(defn parse-body [string-s]
  (when (string? string-s)
    (->> (string/split "&" string-s)
         (map (fn [val] (string/split "=" val)))
         (flatten)
         (apply table)
         (helper/map-keys keyword)
         (helper/map-vals decode-string))))
