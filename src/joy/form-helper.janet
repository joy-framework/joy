(import ./router :as router)
(import ./middleware :as middleware)
(import ./helper :prefix "")


(defn- field [kind val key & attrs]
  [:input (merge {:type kind :name (string key) :value (get val key)} (table ;attrs))])


(def hidden-field
  `(hidden-field val key & attrs)

   Generates an <input type="hidden" /> html element where
   val is a dictionary and key is the value html attribute of a key
   in the val dictionary. If key is nil, an error will be thrown.

   Ex.

   (hidden-field {:a "a" :b "b"} :a :class "a-class" :style "a-style")
   (hidden-field {:a "a" :b "b"} :b)`
  (partial field "hidden"))


(def text-field
  `(text-field val key & attrs)

   Generates an <input type="text" /> html element where
   val is a dictionary and key is the value html attribute of a key
   in the val dictionary. If key is nil, an error will be thrown.

   Ex.

   (text-field {:a "a" :b "b"} :a :class "a-class" :style "a-style")
   (text-field {:a "a" :b "b"} :b)`
  (partial field "text"))


(def email-field
  `(email-field val key & attrs)

   Generates an <input type="email" /> html element where
   val is a dictionary and key is the value html attribute of a key
   in the val dictionary. If key is nil, an error will be thrown.

   Ex.

   (email-field {:a "a" :b "b"} :a :class "a-class" :style "a-style")
   (email-field {:a "a" :b "b"} :b)`
  (partial field "email"))


(def password-field
  `(password-field val key & attrs)

   Generates an <input type="password" /> html element where
   val is a dictionary and key is the value html attribute of a key
   in the val dictionary. If key is nil, an error will be thrown.

   Ex.

   (password-field {:a "a" :b "b"} :a :class "a-class" :style "a-style")
   (password-field {:a "a" :b "b"} :b)`
  (partial field "password"))


(def file-field
  `(file-field val key & attrs)

   Generates an <input type="file" /> html element where
   val is a dictionary and key is the value html attribute of a key
   in the val dictionary. If key is nil, an error will be thrown.

   Ex.

   (file-field {:a "a" :b "b"} :a :class "a-class" :style "a-style")
   (file-field {:a "a" :b "b"} :b)`
  (partial field "file"))


(defn form-for
  `Generates a <form> html element where action-args is a tuple
   of [request route-keyword route-arg1 route-arg2...] and
   body is the rest of the form. The form requires the request for
   the csrf-token and any put, patch or delete http methods.
   These get put in the _method hidden input.

   Ex.

   (form-for [request :account/patch {:id 1}]
    (label :name "Account name")
    (text-field {:name "name"} :name)
    (submit "Save name"))`
  [action-args & body]
  (let [[request] action-args
        action (apply router/action-for (drop 1 action-args))]
    [:form action
      body
      (when (get request :csrf-token)
        [:input {:type "hidden" :name "__csrf-token" :value (middleware/form-csrf-token request)}])
      (when (truthy? (action :_method))
        (hidden-field action :_method))]))


(defn form-with
  [request &opt options & body]
  `
  Generates an html <form> element where the request is the request dictionary and options
  are any form options.

  Options can look like this:

  {:route <a route keyword>
   :route [:route {:id 1}] <- routes with args
   :method "method"
   :action "/"
   :class ""
   :enctype ""}

  Examples:

  (form-with request {:route :account/new :enctype "multipart/form-data"}
    (label :name "name")
    (file-field {} :name)
    (submit "Upload file"))

  (form-with request (merge (action-for :account/edit {:id 1}) {:enctype "multipart/form-data"})
    (label :name "name")
    (file-field {} :name)
    (submit "Upload file"))`
  (default options {})
  (let [{:action action :route route} options
        action (if (truthy? action)
                 {:action action}
                 (if (truthy? route)
                   (router/action-for ;(if (indexed? route) route [route]))
                   {:action ""}))
        options (select-keys options [:class :enctype :method])]
    [:form (merge options action)
      body
      (when (get request :csrf-token)
        [:input {:type "hidden" :name "__csrf-token" :value (middleware/form-csrf-token request)}])
      (when (truthy? (get action :_method))
        (hidden-field action :_method))]))


(defn label
  `Generates a <label> html element where html-for
   is the for attribute value (as a keyword) and the
   body is usually just the label's string value, args
   represents the rest of the attributes, if any.

   Ex.

   (label :name "Account name")
   (label :name "Account name" :class "form-label")`
  [html-for body & args]
  [:label (merge {:for (string html-for)} (table ;args))
    body])


(defn submit
  `Generates an <input type="submit" /> html element
   where value is the value attribute and the args
   are any html attributes.

   Ex.

   (submit "Save")
   (submit "Save" :class "btn btn-submit")`
  [value & args]
  [:input (merge {:type "submit" :value value} (table ;args))])

