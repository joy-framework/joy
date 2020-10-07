(use joy)

(route :get "/" :home)

(defn home [request]
  [:div {:class "tc"}
   [:h1 "You found joy!"]
   [:p {:class "code"}
    [:b "Joy Version:"]
    [:span (string " " version)]]
   [:p {:class "code"}
    [:b "Janet Version:"]
    [:span janet/version]]])
