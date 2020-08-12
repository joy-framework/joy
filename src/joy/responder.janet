(import json)
(import ./html)
(import path)
(import musty)

(defn- content-type [k]
  (let [content-types {:html "text/html; charset=utf-8"
                       :json "application/json"
                       :text "text/plain"
                       :xml "text/xml"}]
    (or (get content-types k) "application/octet-stream")))


(defn flash [response s]
  (put response :flash s))


(defn redirect [url]
  @{:status 302
    :body " "
    :headers @{"Location" url
               "Turbolinks-Location" url}})


(defn respond [ct body & options]
  (default options [])
  (let [options (apply table options)
        @{:status status
          :headers headers} options
        headers (merge @{"Content-Type" (content-type ct)} (or headers @{}))]
    @{:status (or status 200)
      :headers headers
      :body body}))


(def render respond)


(defn text/plain [body]
  @{:status 200
    :body body
    :headers @{"Content-Type" "text/plain"}})


(defn application/json [body]
  @{:status 200
    :body (json/encode body)
    :headers @{"Content-Type" "application/json"}})


(defn text/html [& args]
  @{:status 200
    :body (html/encode ;args)
    :headers @{"Content-Type" "text/html"}})


(defmacro bind [name value]
  ~(setdyn (symbol ,(string name)) ,value))


(defn mustache-name [name]
  (string (path/join "views" name) ".mustache"))


(defn view [name]
  (def mustache-name (mustache-name name))
  (def replacements (as-> (filter (partial string/has-prefix? "@") (all-bindings)) ?
                          (mapcat |(tuple (keyword $) (dyn $)) ?)
                          (struct ;?)))

  (when (os/stat mustache-name)
    (musty/render (slurp mustache-name) replacements)))
