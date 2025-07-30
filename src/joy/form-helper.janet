(import ./router :as router)
(import ./helper :prefix "")
(import ./csrf :prefix "")

(defn- field [kind name & attrs]
  [:input (merge {:type kind :name (string name)} (struct ;attrs))])


(defn hidden-field
  `(hidden-field name & attrs)

   Generates an <input type="hidden" /> html element where
   name is a keyword denoting the name html attribute.

   Ex.

   (hidden-field :myhiddenfield :value "hiddenvalue" :class "a-class" :style "a-style")
   (hidden-field :api-token :value "secret-token")
   (hidden-field :valueless-hidden-field)`
  [name & attrs]
  (field "hidden" name ;attrs))


(defn text-field
  `(text-field name & attrs)

   Generates an <input type="text" /> html element where
   name is a keyword denoting the name html attribute.

   Ex.

   (text-field :username :placeholder "Enter Username" :class "a-class" :style "a-style")
   (text-field :some-prefilled-text :value "I am prefilled!")
   (text-field :text-field)`
  [name & attrs]
  (field "text" name ;attrs))


(defn email-field
  `(email-field name & attrs)

   Generates an <input type="email" /> html element where
   name is a keyword denoting the name html attribute.

   Ex.

   (email-field :email-address :placeholder "Email" :value "me@example.com")
   (email-field :email :class "a-class" :style "a-style")
   (email-field :email)`
  [name & attrs]
  (field "email" name ;attrs))


(defn password-field
  `(password-field name & attrs)

   Generates an <input type="password" /> html element where
   name is a keyword denoting the name html attribute.

   Ex.

   (password-field :pass-field :placeholder "Password" :class "a-class" :style "a-style")
   (password-field :pswd :class "a-class" :style "a-style")
   (password-field :pswd)`
  [name & attrs]
  (field "password" name ;attrs))


(defn file-field
  `(file-field name & attrs)

   Generates an <input type="file" /> html element where
   name is a keyword denoting the name html attribute.

   Ex.

   (file-field :file-field :accept "image/*,.pdf")
   (file-field :file-field :class "a-class" :style "a-style")
   (file-field :file-field)`
  [name & attrs]
  (field "file" name ;attrs))


(defn checkbox-field
  `(checkbox-field name checked? & attrs)

   Generates two inputs, one hidden and one checkbox
   where name is a keyword denoting the name html attribute,
   and checked? is a boolean denoting whether the checkbox is
   checked by default.

   Ex.

   (checkbox-field :neovim? true :true "you're cool" :false "reconsider")
   (checkbox-field :something false :class "a-class" :style "a-style")

   =>

   <input type="hidden" name="neovim?" value="reconsider" />
   <input type="checkbox" name="enabled" value="you're cool" checked="" />
   
   <input type="hidden" name="something" value="0" class="a-class" style="a-style" />
   <input type="checkbox" name="something" value="1" class="a-class" style="a-style" />`
  [name checked? & attrs]
  (let [checked (if checked? {:checked ""} {})
        attrs (struct ;attrs)]
    [(hidden-field name :value (get attrs :false 0))
     [:input (merge {:type "checkbox" :name (string name) :value (get attrs :true 1)}
                    checked
                    attrs)]]))


(defn form-for
  `(form-for action-args & body)
  
   Generates a <form> html element where action-args is a tuple
   of [request route-keyword route-arg1 route-arg2...] and
   body is the rest of the form. The form requires the request for
   the csrf-token and any put, patch or delete http methods.
   These get put in the _method hidden input.

   Ex.

   (form-for [request :account/patch {:id 1}]
    (label :name "Account name")
    (text-field :name)
    (submit "Save name"))`
  [action-args & body]
  (let [[request] action-args
        action (apply router/action-for (drop 1 action-args))
        _method (action :_method)]
    [:form action
      body
      (csrf-field request)
      (when (truthy? _method)
        (hidden-field :_method :value _method))]))


(defn form-with
  `(form-with request &opt options & body)

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
    (file-field :name)
    (submit "Upload file"))

  (form-with request (merge (action-for :account/edit {:id 1}) {:enctype "multipart/form-data"})
    (label :name "name")
    (file-field :name)
    (submit "Upload file"))`
  [request &opt options & body]
  (default options {})
  (let [{:action action :route route} options
        action (if (truthy? action)
                 {:action action}
                 (if (truthy? route)
                   (router/action-for ;(if (indexed? route) route [route]))
                   {:action ""}))
        attrs (merge options action)
        _method (get attrs :_method)]
    [:form attrs
      body
      (csrf-field request)
      (when (truthy? _method)
        (hidden-field :_method :value _method))]))


(defn label
  `(label html-for body & attrs)
  
   Generates a <label> html element where html-for
   is the for attribute value (as a keyword) and the
   body is usually just the label's string value, args
   represents the rest of the attributes, if any.

   Ex.

   (label :name "Account name")
   (label :name "Account name" :class "form-label")`
  [html-for body & attrs]
  [:label (merge {:for (string html-for)} (table ;attrs))
    body])


(defn label-for [html-for & body]
  [:label {:for html-for}
   body])



(defn submit
  `(submit value & attrs)
  
   Generates an <input type="submit" /> html element
   where value is the value attribute and the args
   are any html attributes.

   Ex.

   (submit "Save")
   (submit "Save" :class "btn btn-submit")`
  [value & attrs]
  [:input (merge {:type "submit" :value value} (table ;attrs))])
