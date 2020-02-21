(import ./src/server :as server)

(defn main [& args]
  (server/start (get args 1)))
