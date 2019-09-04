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
  (if (dictionary? val)
    (string " "
      (string/join
        (map (fn [[k v]] (string k "=" `"` v `"`))
          (pairs val))
        " "))
    ""))


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
                   :else "")
                 "</" (string el) ">"))
             ""))
      args)
    ""))
