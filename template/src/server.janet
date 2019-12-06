(import joy :prefix "")
(import ./layout :as layout)
(import ./routes :as routes)

(def db (env :db-name))

(def app (-> (app routes/app)
             (set-db db)
             (set-layout layout/app)
             (session)
             (body-parser)
             (extra-methods)
             (query-string)
             (body-parser)
             (server-error)
             (logger)
             (static-files)))

(defn start [port]
  (server app port))
