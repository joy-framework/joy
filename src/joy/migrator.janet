(import ./helper :as helper)
(import ./db :as db)


(def- up-token "-- up")
(def- down-token "-- down")
(def- migrations-dir "db/migrations")


(defn parse-migration [sql]
  (let [parts (string/split "\n" sql)
        up-index (find-index |(= $ up-token) parts)
        down-index (find-index |(= $ down-token) parts)
        up-sql (-> (array/slice parts (inc up-index) down-index)
                   (string/join "\n"))
        down-sql (-> (array/slice parts (inc down-index) -1)
                     (string/join "\n"))]
    {:up up-sql
     :down down-sql}))


(defn- file-migration-map []
  (->> (os/dir migrations-dir)
       (mapcat |(tuple (-> (string/split "-" $)
                           (first))
                       $))
       (apply struct)))


(defn- db-versions [conn]
  (->> (db/query conn "select version from schema_migrations order by version")
       (map |(get $ :version))))


(defn pending-migrations [db-versions file-migration-map]
  (let [versions (->> (array/concat @[] (keys file-migration-map) db-versions)
                      (frequencies)
                      (pairs)
                      (filter (fn [[_ v]] (= v 1)))
                      (map first)
                      (sort))]
    (map |(get file-migration-map $) versions)))


(defn migrate [db-name]
  (db/with-db-connection [conn db-name]
    (db/execute conn "create table if not exists schema_migrations (version text primary key)")
    (let [migrations (pending-migrations (db-versions conn) (file-migration-map))]
      (loop [migration :in migrations]
        (helper/with-file [f (string migrations-dir "/" migration)]
          (let [version (-> (string/split "-" migration)
                            (first))
                up (-> (file/read f :all)
                       (parse-migration)
                       (get :up))]
            (print "Migrating [" migration "]...")
            (print up)
            (db/execute conn up)
            (db/execute conn "insert into schema_migrations (version) values (:version)" {:version version})
            (let [rows (db/query conn "select sql from sqlite_master where sql is not null order by rootpage")]
              (helper/with-file [f "db/schema.sql" :w]
                (file/write f
                   (string/join
                     (map |(get $ :sql) rows)
                     "\n"))))
            (print "Successfully migrated [" migration "]")))))))


(defn rollback [db-name]
  (db/with-db-connection [conn db-name]
    (db/execute conn "create table if not exists schema_migrations (version text primary key)")
    (let [version (last (db-versions conn))
          migration (get (file-migration-map) version)]
      (helper/with-file [f (string migrations-dir "/" migration)]
        (let [down (-> (file/read f :all)
                       (parse-migration)
                       (get :down))]
          (print "Rolling back [" migration "]...")
          (print down)
          (db/execute conn down)
          (db/execute conn "delete from schema_migrations where version = :version" {:version version})
          (let [rows (db/query conn "select sql from sqlite_master where sql is not null order by rootpage")]
            (helper/with-file [f "db/schema.sql" :w]
              (file/write f
                 (string/join
                   (map |(get $ :sql) rows)
                   "\n"))))
          (print "Successfully rolled back [" migration "]"))))))


