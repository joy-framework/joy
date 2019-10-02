(import ./helper :as helper)


(defn get-dotenv [key]
  (let [f (file/open ".env" :r)]
    (when (not (nil? f))
      (let [dot-env-table (->> (file/read f :all)
                               (string/split "\n")
                               (map |(string/split "=" $))
                               (flatten)
                               (filter |(not (empty? $)))
                               (map string/trim)
                               (apply table))
            value (get dot-env-table key)]
        (file/close f)
        value))))


(defn get-env [key]
  (when (keyword? key)
    (let [env-key (-> key string helper/snake-case string/ascii-upper)]
      (or (os/getenv env-key)
          (get-dotenv env-key)))))
