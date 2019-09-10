(import ./helper :as helper)

(defn env [key]
  (-> key string helper/snake-case string/ascii-upper os/getenv))
