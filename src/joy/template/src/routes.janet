(import joy :prefix "")
(import ./routes/home :as home)

(defroutes app
  [:get "/" home/index])
