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
                   (string? content) content
                   (string? attr-or-content) attr-or-content
                   (indexed? attr-or-content) (render attr-or-content)
                   (indexed? content) (render content)
                   :else "")
                 "</" (string el) ">"))
             ""))
      args)
    ""))
