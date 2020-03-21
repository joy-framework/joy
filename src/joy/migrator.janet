(import ./db1 :as db)
(import path)


(defn- file/read-all [filename]
  (with [f (file/open filename :r)]
    (file/read f :all)))


(defn- file/write-all [filename contents]
  (with [f (file/open filename :w)]
    (file/write f contents)))



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
        (let [version (-> (string/split "-" migration)
                          (first))
              filename (path/join migrations-dir migration)
              up (as-> filename ?
                       (file/read-all ?)
                       (parse-migration ?)
                       (get ? :up))]
          (print "Migrating [" migration "]...")
          (print up)
          (db/execute conn up)
          (db/execute conn "insert into schema_migrations (version) values (:version)" {:version version})
          (let [rows (db/query conn "select sql from sqlite_master where sql is not null order by rootpage")
                schema-sql (as-> rows ?
                                 (map |(get $ :sql) ?)
                                 (string/join ? "\n"))]
            (file/write-all "db/schema.sql" schema-sql))
          (print "Successfully migrated [" migration "]"))))))


(defn rollback [db-name]
  (db/with-db-connection [conn db-name]
    (db/execute conn "create table if not exists schema_migrations (version text primary key)")
    (let [version (last (db-versions conn))
          migration (get (file-migration-map) version)
          filename (path/join migrations-dir migration)
          down (as-> filename ?
                     (file/read-all ?)
                     (parse-migration ?)
                     (get ? :down))]
      (print "Rolling back [" migration "]...")
      (print down)
      (db/execute conn down)
      (db/execute conn "delete from schema_migrations where version = :version" {:version version})
      (let [rows (db/query conn "select sql from sqlite_master where sql is not null order by rootpage")
            schema-sql (as-> rows ?
                             (map |(get $ :sql) ?)
                             (string/join ? "\n"))]
        (file/write-all "db/schema.sql" schema-sql))
      (print "Successfully rolled back [" migration "]"))))


