(import ./helper :prefix "")

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
    (string/format "%d-%.2d-%.2d %.2d:%.2d:%.2d"
                   Y M D HH MM SS)))


(defn- surround [s]
  (if (and (string? s) (string/find " " s))
    (string `"` s `"`)
    s))


(defn- logfmt [ind]
  (as-> ind ?
        (partition 2 ?)
        (filter |(not (nil? (get $ 1))) ?)
        (map (fn [[k v]] (string (surround k) "=" (surround v))) ?)
        (string/join ? " ")))


(defn- responsefmt [request response]
  [:method (request :method)
   :uri (request :uri)
   :content-type (content-type response)
   :status (response :status)
   :duration (string/format "%.1fms" (* (response :duration) 1000))])


(defn- log [str]
  (printf "[%s] %s" (timestamp) str))


(defn logger [handler &opt options]
  (def options (if (dictionary? options)
                 (merge {:level "info"} options)
                 {:level "info"}))

  (fn [request]
    (let [start-seconds (os/clock)
          response (handler request)
          end-seconds (os/clock)
          level (get response :level (get options :level))]

      (when (= level (get options :level))
        (as-> response ?
              (put ? :duration (- end-seconds start-seconds))
              (responsefmt request ?)
              (logfmt ?)
              (log ?)))

      response)))
