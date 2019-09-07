(import "src/joy/helper" :as helper)


(defn set-layout [handler layout]
  (fn [request]
    (let [response (handler request)]
      (if (or (indexed? response)
              (and (dictionary? response)
                   (= 200 (get response :status))))
        (layout {:status 200 :body response})
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


(defn decode-string [s]
  (let [escape-chars {"%20" " " "%3C" "<" "%3E" ">" "%23" `#` "%25" "%"
                      "%7B" "{" "%7D" "}" "%7C" "|" "%5C" `\` "%5E" "^"
                      "%7E" "~" "%5B" "[" "%5D" "]" "%60" "`" "%3B" `;`
                      "%2F" "/" "%3F" "?" "%3A" ":" "%40" "@" "%3D" "="
                      "%26" "&" "%24" "$"}]
    (var output s)
    (loop [[k v] :in (pairs escape-chars)]
      (set output (string/replace-all k v output)))
    output))


(defn parse-body [string-s]
  (->> (string/split "&" string-s)
       (map (fn [val] (string/split "=" val)))
       (flatten)
       (apply table)
       (helper/map-keys keyword)
       (helper/map-vals decode-string)))


(defn body-parser [handler]
  (fn [request]
    (let [{:body body} request
          body ()]
      (handler (put request :body body)))))
