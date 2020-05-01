(import ./helper :as helper)

(defn- timestamp
  "Get the current date nicely formatted"
  []
  (let [date (os/date)
        M (+ 1 (date :month))
        D (+ 1 (date :month-day))
        Y (date :year)
        HH (date :hours)
        MM (date :minutes)
        SS (date :seconds)]
    (string/format "[%d-%.2d-%.2d %.2d:%.2d:%.2d]"
                   Y M D HH MM SS)))


(defn- surround [s]
  (if (string/find " " s)
    (string `"` s `"`)
    s))


(defn- format-key-value-pairs [[k v]]
  (when (not (nil? v))
    (let [val (if (string? v)
                v
                (string/format "%q" v))]
      (string k "=" (surround val)))))


(defn- message [level msg &opt kv-pairs]
  (string "at=" (surround level) " msg=" (surround msg)
    (if (indexed? kv-pairs)
      (string " "
        (string/join
          (->> (partition 2 kv-pairs)
               (map format-key-value-pairs)
               (filter |(not (nil? $))))
          " "))
      "")))


(defn log-string [options]
  (let [{:level level :msg msg :attrs attrs :ts ts} options
        ts (or ts (timestamp))]
    (string ts " " (message level msg attrs))))


(defn log [options]
  (let [log-line (log-string options)]
    (print log-line)
    log-line))


(defn request-struct [request options]
  (let [{:uri uri :protocol proto
         :method method :params params
         :body body} request
        params (helper/select-keys params (get options :ignore-keys))
        body (helper/select-keys body (get options :ignore-keys))
        method (string/ascii-upper method)
        attrs @[:method method :url uri]
        attrs (if (empty? params) attrs (array/concat attrs [:params params]))
        attrs (if (empty? body) attrs (array/concat attrs [:body body]))]
    {:level "info"
     :msg (string/format "Started %s %s" method uri)
     :ts (timestamp)
     :attrs (freeze attrs)}))


(defn response-struct [request response start-seconds end-seconds]
  (let [{:status status} response
        {:method method :uri uri :duration duration} request
        method (string/ascii-upper method)
        content-type (or (get-in response [:headers "Content-Type"])
                         (get-in response [:headers "content-type"]))]
    {:ts (timestamp)
     :level "info"
     :msg (string/format "Finished %s %s" method uri)
     :attrs [:method method :url uri :status status :duration duration :content-type content-type]}))


(defn logger [handler &opt options]
  (default options {:ignore-keys [:password :confirm-password]})
  (fn [request]
    (def start-seconds (os/clock))
    (log (request-struct request options))
    (def response (handler request))
    (def end-seconds (os/clock))
    (put request :duration (string/format "%.4fms" (- end-seconds start-seconds)))
    (when response
      (log (response-struct request response start-seconds end-seconds)))

    response))
