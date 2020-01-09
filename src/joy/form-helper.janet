(import ./router :as router)

(defn- field [kind val key &opt attrs]
  (default attrs [])
  [:input (merge {:type kind :name (string key) :value (get val key)} (apply table attrs))])


(def hidden-field (partial field "hidden"))
(def text-field (partial field "text"))
(def email-field (partial field "email"))
(def password-field (partial field "password"))


(defn form-for [action-args & body]
  (let [[request] action-args
        action (apply router/action-for (drop 1 action-args))]
    [:form action
      body
      (when (truthy? (request :csrf-token))
        (hidden-field request :csrf-token))
      (when (truthy? (action :_method))
        (hidden-field action :_method))]))


(defn label [key & args]
  (let [str (string key)]
    [:label (merge {:for str :style "display: block;"} (table ;args))
      str]))


(defn submit [value & args]
  [:input (merge {:type "submit" :value value :style "display: block"} (apply table args))])

