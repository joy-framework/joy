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
    (string/format "%d%.2d%.2d%.2d%.2d%.2d" Y M D HH MM SS)))


(defn create [name]
  (os/mkdir "db")
  (os/mkdir "db/migrations")
  (when (string? name)
    (with [f (file/open (string "db/migrations/" (timestamp) "-" name ".sql") :w)]
      (file/write f "-- up\n\n-- down"))))
