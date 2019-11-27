# src/joy/logger.janet

(defn timestamp
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


(defn surround [s]
  (if (string/find " " s)
    (string `"` s `"`)
    s))


(defn format-key-value-pairs [[k v]]
  (when (not (nil? v))
    (let [val (if (string? v)
                v
                (string/format "%q" v))]
      (string k "=" (surround val)))))


(defn message [level msg &opt kv-pairs]
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


(defn middleware [handler]
  (fn [request]
    (let [start (os/clock)
          {:uri uri :protocol proto
           :method method :params params} request
          request-log (log {:level "info"
                            :msg (string "Started " (string/ascii-upper method) " " uri)
                            :ts (timestamp)
                            :attrs [:protocol proto :method (string/ascii-upper method) :url uri :params params]})
          response (handler (apply table (kvs request)))
          end (os/clock)
          duration (string/format "%.0fms" (* 1000 (- end start)))
          {:status status} response
          response-log (log {:ts (timestamp)
                             :level "info"
                             :msg (string "Finished" " " (string/ascii-upper method) " " uri)
                             :attrs [:protocol proto :method method :url uri :status status :duration duration]})]
       response)))
