(defn env [key]
  (-> key string string/ascii-upper os/getenv))
