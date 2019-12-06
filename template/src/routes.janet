(import joy :prefix "")
(import ./routes/home :as home)

(def home-routes
  (routes
    [:get "/" home/index]))

(def app
  (routes
    home-routes))
