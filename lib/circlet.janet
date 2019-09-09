(import build/circlet :as circlet)


(defn server
  "Creates a simple http server"
  [handler port &opt ip-address]
  (default ip-address "localhost")
  (def mgr (circlet/manager))
  (def interface (if (peg/match "*" ip-address)
                   (string port)
                   (string/format "%s:%d" ip-address port)))
  (defn evloop []
    (print (string/format "Circlet server listening on [%s:%d] ..." ip-address port))
    (var req (yield nil))
    (while true
      (set req (yield (handler req)))))
  (circlet/bind-http mgr interface evloop)
  (while true (circlet/poll mgr 1)))
