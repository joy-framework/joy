(defn escape [string-arg]
  (let [struct-chars [["&" "&amp;"]
                      ["<" "&lt;"]
                      [">" "&gt;"]
                      ["\"" "&quot;"]]]
    (var string-escaped string-arg)
    (loop [[k v] :in struct-chars]
      (set string-escaped (string/replace-all k v string-escaped)))
    string-escaped))


(defn attributes [val]
  (if (and (dictionary? val)
        (nil? (get val :raw)))
    (string " "
      (string/join
        (map (fn [[k v]] (string k "=" `"` v `"`))
          (pairs val))
        " "))
    ""))


(defn raw [val]
  {:raw val})


(defn render [& args]
  (string/join
    (map (fn [val]
           (if (indexed? val)
             (let [[el attr-or-content content] val]
               (string "<" (string el) (attributes attr-or-content) ">"
                 (cond
                   (string? content) (escape content)
                   (string? attr-or-content) (escape attr-or-content)
                   (indexed? attr-or-content) (render attr-or-content)
                   (indexed? content) (render content)
                   (dictionary? attr-or-content) (get attr-or-content :raw "")
                   (dictionary? content) (get content :raw "")
                   :else "")
                 "</" (string el) ">"))
             ""))
      args)
    ""))
