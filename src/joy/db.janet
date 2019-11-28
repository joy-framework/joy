(import sqlite3)
(import ./helper :as helper)
(import ./db/sql :as sql)


(defmacro with-connection
  `A macro that takes a binding array, ex: [conn "x.sqlite3"] and expressions and executes them in the context of the connection.

   Example:

   (import sqlite3)

   (with-connection [db "dev.sqlite3"]
     (sqlite3/eval db "select 1;" {}))`
  [binding & body]
  (with-syms [$rows]
   ~(let [,(first binding) (,sqlite3/open ,(get binding 1))
          ,$rows ,(splice body)]
      (,sqlite3/close ,(first binding))
      ,$rows)))


(defn query [db sql &opt params]
  (default params {})
  (let [sql (string sql ";")]
    (->> (sqlite3/eval db sql params)
         (map (partial helper/map-keys keyword)))))


(defn execute [db sql &opt params]
  (default params {})
  (let [sql (string sql ";")]
    (sqlite3/eval db sql params)
    (sqlite3/last-insert-rowid db)))


(defn last-inserted [db table-name rowid]
  (let [params {:rowid rowid}
        sql (sql/from table-name {:where params :limit 1})]
    (first
      (query db sql params))))


(defn fetch [db path & args]
  (let [args (apply table args)
        sql (sql/fetch path (merge args {:limit 1}))
        params (sql/fetch-params path)]
    (->> (query db sql params)
         (first))))


(defn fetch-all [db path & args]
  (let [sql (sql/fetch path (apply table args))
        params (sql/fetch-params path)]
    (query db sql params)))


(defn from [db table-name & args]
  (let [opts (apply table args)
        sql (sql/from table-name opts)
        params (get opts :where {})]
    (query db sql params)))


(defn insert [db table-name params]
  (let [sql (sql/insert table-name params)]
    (->> (execute db sql params)
         (last-inserted db table-name))))


(defn insert-all [db table-name arr]
  (let [sql (sql/insert-all table-name arr)
        params (sql/insert-all-params arr)]
    (execute db sql params)
    (query db (string "select * from " (helper/snake-case table-name) " order by rowid limit " (length params)))))


(defn update [db table-name id params]
  (let [sql (sql/update table-name params)]
    (execute db sql (merge params {:id id}))
    (fetch db [table-name id])))


(defn update-all [db table-name where-params set-params]
  (let [rows (from db table-name where-params)
        sql (sql/update-all table-name where-params set-params)
        params (sql/update-all-params where-params set-params)]
    (execute db sql params)
    (from db table-name (map |(table :id (get $ :id))
                          rows))))


(defn delete [db table-name id]
  (let [row (fetch db [table-name id])
        sql (sql/delete table-name id)
        params {:id id}]
    (execute db sql params)
    row))


(defn delete-all [db table-name params &opt where-params]
  (let [rows (from db table-name params)
        params (or where-params params)
        sql (sql/delete-all table-name params)]
    (execute db sql params)
    rows))
