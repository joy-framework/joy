(use joy)


(defn layout [{:body body :request request}]
  (text/html
    (doctype :html5)
    [:html {:lang "en"}
     [:head
      [:title "%project-name%"]
      [:meta {:charset "utf-8"}]
      [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
      [:meta {:name "csrf-token" :content (authenticity-token request)}]
      [:link {:rel "stylesheet" :href "/app.css"}]
      [:script {:src "/app.js" :defer ""}]]
     [:body
       body]]))


(defn home [request]
  [:div {:class "tc"}
   [:h1 "You found joy!"]
   [:p {:class "code"}
    [:b "Joy Version:"]
    [:span (string " " version)]]
   [:p {:class "code"}
    [:b "Janet Version:"]
    [:span janet/version]]])


(def routes (routes [:get "/" home]))


(def app (app {:routes routes
               :layout layout}))


(server app (env :port))
