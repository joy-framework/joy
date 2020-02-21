(import joy :prefix "")
(import ./layout :as layout)
(import ./routes :as routes)


(def app (as-> routes/app ?
               (handler ?)
               (layout ? layout/app)
               (logger ?)
               (csrf-token ?)
               (session ?)
               (extra-methods ?)
               (query-string ?)
               (body-parser ?)
               (server-error ?)
               (x-headers ?)
               (static-files ?)))


(defn start [port]
  (let [port (scan-number
              (or port
                  (env :port)
                  "8000"))]
    (db/connect)
    (server app port) # stops listening on SIGINT
    (db/disconnect)))
