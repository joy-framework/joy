(import ./helper :as helper)


(defn parse-dotenv [dot-env-string]
  (when (not (nil? dot-env-string))
    (->> (string/split "\n" dot-env-string)
         (mapcat |(string/split "=" $ 0 2))
         (filter |(not (empty? $)))
         (map string/trim)
         (apply table))))


(defn- dotenv [key]
  (when (os/stat ".env")
    (helper/with-file [f ".env" :r]
      (-> (file/read f :all)
          (parse-dotenv)
          (get key)))))


(defn env
  `Returns a key from either a .env file or the system's environment

   Example:

   Given a .env file or a system env like this

   JOY_ENV=development

   (env :joy-env) => "development"`
  [key]
  (when (keyword? key)
    (let [env-key (-> key string helper/snake-case string/ascii-upper)]
      (or (os/getenv env-key)
          (dotenv env-key)))))


(def development? (= "development" (env :joy-env)))
(def test? (= "test" (env :joy-env)))
(def production? (= "production" (env :joy-env)))