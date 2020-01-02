(import joy :prefix "")

(defn index [request]
  [:div {:class "tc"}
   [:h1 "You found joy!"]
   [:img {:src "/joy.png"
          :srcset "joy.png 1x, joy@2x.png 2x, joy@3x.png 3x"
          :class "w-100"}]
   [:p {:class "code"}
    [:b "Joy Version:"]
    [:span (string " " joy/version)]]
   [:p {:class "code"}
    [:b "Janet Version:"]
    [:span janet/version]]])
