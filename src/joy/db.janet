(import sqlite3)
(import ./helper :as helper)
(import ./db/sql :as sql)


(defmacro with-connection [binding & body]
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
        sql (sql/from table-name params)]
    (first
      (query db sql params))))


(defn fetch [db table-name path & args]
  (let [sql (sql/fetch table-name path (merge (or args {}) {:limit 1}))
        params (sql/fetch-params path)]
    (->> (query db sql params)
         (first))))


(defn fetch-all [db table-name path & args]
  (let [sql (sql/fetch table-name path args)
        params (sql/fetch-params table-name path args)]
    (query db sql params)))


(defn from [db table-name params & args]
  (let [sql (sql/from table-name params)]
    (query db sql params)))


(defn insert [db table-name params]
  (->> (execute db (sql/insert table-name params))
       (last-inserted db table-name)))


(defn insert-all [db table-name arr]
  (let [_ (execute db (sql/insert-all table-name arr) (sql/insert-all-params arr))]
    (query db (string "select * from " (helper/snake-case table-name) " order by rowid limit " (length params)))))


(defn update [db table-name id params]
  (execute db (sql/update table-name params) (merge params {:id id}))
  (fetch db [table-name id]))


(defn update-all [db table-name where-params set-params]
  (let [rows (from db table-name where-params)
        sql (sql/update-all table-name where-params set-params)
        params (sql/update-all-params where-params set-params)]
    (execute db sql params)
    (from db table-name (map |(table :id (get $ :id))
                          rows))))


(defn delete [db table-name id]
  (let [row (fetch db [table-name id])]
    (execute db (sql/delete table-name id) {:id id})
    row))


(defn delete-all [db table-name params &opt where-params]
  (let [rows (from db table-name params)]
    (execute db (sql/delete-all table-name (or where-params params)) (or where-params params))
    rows))
