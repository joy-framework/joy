(defn timestamp
  `
  Get the current date nicely formatted for migrations

  Example:

  (import joy/cli/migrations)

  (migrations/timestamp) => 20200508165811
  `
  []
  (let [date (os/date)
        M (+ 1 (date :month))
        D (+ 1 (date :month-day))
        Y (date :year)
        HH (date :hours)
        MM (date :minutes)
        SS (date :seconds)]
    (string/format "%d%.2d%.2d%.2d%.2d%.2d" Y M D HH MM SS)))


(defn create [name &opt content]
  (default content {})
  (os/mkdir "db")
  (os/mkdir "db/migrations")
  (when (string? name)
    (let [{:up up :down down} content]
      (with [f (file/open (string "db/migrations/" (timestamp) "-" name ".sql") :w)]
        (file/write f
          (string "-- up\n" (or up "") "\n\n-- down\n" (or down "")))))))
