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


(defn doctype [version &opt style]
  (let [key [version (or style "")]]
    (get {[:html5 ""] (raw "<!DOCTYPE HTML>")
          [:html4 :strict] (raw `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">`)
          [:html4 :transitional] (raw `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">`)
          [:html4 :frameset] (raw `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">`)
          [:xhtml1.0 :strict] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">`)
          [:xhtml1.0 :transitional] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">`)
          [:xhtml1.0 :frameset] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">`)
          [:xhtml1.1 ""] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">`)
          [:xhtml1.1 :basic] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">`)}
      key)))


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
