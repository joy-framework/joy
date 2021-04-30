(defn parse-dotenv [dot-env-string]
  (when dot-env-string
    (->> (string/split "\n" dot-env-string)
         (mapcat |(string/split "=" $ 0 2))
         (filter |(not (empty? $)))
         (map string/trim)
         (apply table))))


(defn- dotenv [key]
  (when (os/stat ".env")
    (with [f (file/open ".env")]
      (-> (file/read f :all)
          (parse-dotenv)
          (get key)))))


(defn- snake-case
  `Changes a string from kebab-case to snake_case

   Example

   (snake-case "created-at") -> "created_at"`
  [val]
  (string/replace-all "-" "_" val))


(defn env
  `Returns a key from either a .env file or the system's environment

   Example:

   Given a .env file or a system env like this

   JOY_ENV=development

   (env :joy-env) => "development"`
  [key]
  (when (keyword? key)
    (let [env-key (-> key string snake-case string/ascii-upper)]
      (or (os/getenv env-key)
          (dotenv env-key)))))


(defn setenv []
  (when (os/stat ".env")
    (with [f (file/open ".env")]
      (as-> (file/read f :all) ?
            (parse-dotenv ?)
            (eachp [k v] ?
              (os/setenv k v))))))


(def development? (= "development" (env :joy-env)))
(def test? (= "test" (env :joy-env)))
(def production? (= "production" (env :joy-env)))
