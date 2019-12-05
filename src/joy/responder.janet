# responder.janet

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
    :headers @{"Location" url}})


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
