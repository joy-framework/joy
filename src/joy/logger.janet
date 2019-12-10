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
    (if (tuple? kv-pairs)
      (string " "
        (string/join
          (->> (map format-key-value-pairs (partition 2 kv-pairs))
               (filter (fn [x] (not (nil? x)))))
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


(defn logger [handler &opt options]
  (default options {:ignore-keys [:password :confirm-password]})
  (fn [request]
    (let [start (os/clock)
          {:uri uri :protocol proto
           :method method :params params
           :body body} request
          params (helper/select-keys params (get options :ignore-keys))
          body (helper/select-keys body (get options :ignore-keys))
          method (string/ascii-upper method)
          attrs (filter |(not (empty? $)) [:method method :url uri :params params :body body])
          request-log (log {:level "info"
                            :msg (string/format "Started %s %s" method uri)
                            :ts (timestamp)
                            :attrs attrs})
          response (handler request)
          end (os/clock)
          duration (string/format "%.0fms" (* 1000 (- end start)))
          {:status status} response
          response-log (log {:ts (timestamp)
                             :level "info"
                             :msg (string/format "Finished %s %s" method uri)
                             :attrs [:method method :url uri :status status :duration duration]})]
       response)))
