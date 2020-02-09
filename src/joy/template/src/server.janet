(import joy :prefix "")
(import joy/db)
(import ./layout :as layout)
(import ./routes :as routes)

(db/connect)

(def app (as-> routes/app ?
               (handler ?)
               (layout ? layout/app)
               (logger ?)
               (session ?)
               (extra-methods ?)
               (query-string ?)
               (body-parser ?)
               (server-error ?)
               (x-headers ?)
               (static-files ?)))

(server app 8000)
