(defn set-layout [handler layout]
  (fn [request]
    (let [response (handler request)]
      (if (= (get response :status) 200)
        (joy/respond :html
          (joy/html
            (layout response)))
        response))))


(defn static-files [handler &opt root]
  (fn [request]
    (let [response (handler request)]
      (if (not= 404 (get response :status))
        response
        (let [{:method method} request]
          (if (some (partial = method) ["GET" "HEAD"])
            {:kind :static
             :root (or root "public")}))))))
