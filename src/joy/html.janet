# html.janet
# parts of the code shamelessly stolen from https://github.com/brandonchartier/html

(defn- escape [string-arg]
  (let [struct-chars [["&" "&amp;"]
                      ["<" "&lt;"]
                      [">" "&gt;"]
                      ["\"" "&quot;"]
                      ["%" "&#37;"]]]
    (var string-escaped string-arg)
    (loop [[k v] :in struct-chars]
      (set string-escaped (string/replace-all k v string-escaped)))
    string-escaped))


(defn raw [val]
  [:text val])


(defn doctype [version &opt style]
  (let [key [version (or style "")]
        doctypes {[:html5 ""] (raw "<!DOCTYPE HTML>")
                  [:html4 :strict] (raw `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">`)
                  [:html4 :transitional] (raw `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">`)
                  [:html4 :frameset] (raw `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">`)
                  [:xhtml1.0 :strict] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">`)
                  [:xhtml1.0 :transitional] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">`)
                  [:xhtml1.0 :frameset] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">`)
                  [:xhtml1.1 ""] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">`)
                  [:xhtml1.1 :basic] (raw `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">`)}]
      (get doctypes key "")))


(def- void-elements
  [:area :base :br :col :embed
   :hr :img :input :keygen :link
   :meta :param :source :track :wbr])


(defn- void-element?
  [name]
  (some (partial = name) void-elements))


(defn- text-element?
  [name]
  (= name :text))


(defn- attr-reducer
  [acc [attr value]]
  (string acc " " attr `="` value `"`))


(defn- create-attrs
  [attrs]
  (reduce attr-reducer "" (map (fn [[x y]] [x (escape y)]) (pairs attrs))))


(defn- opening-tag
  [name attrs]
  (string "<" name (create-attrs attrs) (if (void-element? name) " />" ">")))


(defn- closing-tag
  [name]
  (string "</" name ">"))


(defn- first-child
  [children]
  (if (indexed? children)
      (when (not (empty? children))
        (first children))
      children))


(defn- create-children
  [create children]

  (defn child-reducer
    [acc child]
    (string acc (create child)))

  (let [child (first-child children)]
    (cond
      (indexed? child) (reduce child-reducer "" children)
      (keyword? child) (create children)
      (string? child) (escape child)
      (number? child) (string child)
      (nil? child) ""
      (empty? child) ""
      :else children)))


(defn- valid-children?
  [children]
  (or (indexed? children)
      (number? children)
      (string? children)))


(defn- validate-element
  [name attrs children]
  (unless (keyword? name)
          (error "name must be a keyword"))
  (unless (dictionary? attrs)
          (error "attributes must be a dictionary"))
  (unless (valid-children? children)
          (error "children must be a string, number, or index")))


(defn- create-element
  [create name attrs children]
  (validate-element name attrs children)
  (cond
    (void-element? name) (opening-tag name attrs)
    (text-element? name) (first children)
    :else (string (opening-tag name attrs)
            (create-children create children)
            (closing-tag name))))


(defn- create
  [element]
  (if (not (nil? element))
    (if (every? (map indexed? element))
      (string/join (map create element) "")
      (let [[name attrs] element]
        (if (dictionary? attrs)
          (create-element create name attrs (filter truthy? (drop 2 element)))
          (create-element create name {} (filter truthy? (drop 1 element))))))
    ""))


(defn html [& args]
  (string/join (map create args) ""))
