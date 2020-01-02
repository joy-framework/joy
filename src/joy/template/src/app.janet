(import joy :prefix "")
(import ./layout :as layout)
(import ./routes :as routes)


(defn web
  "Default web app middleware"
  [handler]
  (-> handler
      (db (env :db-name))
      (layout layout/app)
      (logger)
      (csrf-token)
      (session)
      (extra-methods)
      (query-string)
      (body-parser)
      (server-error)
      (x-headers)
      (static-files)
      (not-found)))


(def public (-> routes/public
                (handler)
                (web)))


(def app (app public))
