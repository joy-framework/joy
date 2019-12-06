(import ./helper :as helper)


(defn parse-dotenv [dot-env-string]
  (when (not (nil? dot-env-string))
    (->> (string/split "\n" dot-env-string)
         (mapcat |(string/split "=" $ 0 2))
         (filter |(not (empty? $)))
         (map string/trim)
         (apply table))))


(defn- dotenv [key]
  (helper/with-file [f ".env" :r]
    (-> (file/read f :all)
        (parse-dotenv)
        (get key))))


(defn env [key]
  (when (keyword? key)
    (let [env-key (-> key string helper/snake-case string/ascii-upper)]
      (or (os/getenv env-key)
          (dotenv env-key)))))
