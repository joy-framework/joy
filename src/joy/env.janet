(import dotenv :prefix "" :export true)

(def development? (= "development" (env :joy-env)))
(def test? (= "test" (env :joy-env)))
(def production? (= "production" (env :joy-env)))
