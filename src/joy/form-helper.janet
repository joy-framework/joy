(import ./router :as router)

(defn- field [kind val key &opt attrs]
  (default attrs [])
  [:input (merge {:type kind :name (string key) :value (val key)} (apply table attrs))])


(def hidden-field (partial field "hidden"))
(def text-field (partial field "text"))
(def email-field (partial field "email"))
(def password-field (partial field "password"))


(defn form-for [action-args & body]
  (let [[request] action-args
        action (apply router/action-for action-args)]
    [:form action
      body
      (when (not (nil? (request :csrf-token)))
        (hidden-field request :csrf-token))
      (when (not (nil? (action :_method)))
        (hidden-field action :_method))]))


(defn label [key &opt attrs]
  (default attrs [:for (string key)])
  (let [str (string key)]
    [:label (merge {:for str :style "display: block;"} (apply table attrs)) str]))


(defn submit [value &opt attrs]
  (default attrs [])
  [:input (merge {:type "submit" :value value :style "display: block"} (apply table attrs))])

