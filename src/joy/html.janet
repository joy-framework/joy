(defn void-element? [name]
  (let [elements [:area :base :br :col :embed
                  :hr :img :input :keygen :link
                  :meta :param :source :track :wbr]]
    (some (partial = name) elements)))


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
             (let [el (string (first val))
                   attributes (attributes (get val 1))
                   rest (drop (if (= "" attributes) 1 2) val)]
               (if (void-element? (first val))
                 (string "<" el attributes " />")
                 (string "<" el attributes ">"
                   (cond
                     (true? (and (one? (length rest))
                             (string? (first rest)))) (escape (first rest))

                     (true? (and (one? (length rest))
                             (dictionary? (first rest)))) (get (first rest) :raw "")

                     (true? (and (indexed? rest)
                              (> (length rest) 0))) (apply render rest)

                     "")
                   "</" el ">")))
             ""))
      args)
    ""))
