(import joy :prefix "")
(import ./routes/home :as home)

(defroutes public
  [:get "/" home/index])
