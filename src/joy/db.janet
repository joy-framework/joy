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
  (let [sql (sql/fetch table-name path args)
        params (sql/fetch-params table-name path args)
        rows (query db sql params)]
    (first rows)))


(defn fetch-all [db table-name path & args]
  (let [sql (sql/fetch table-name path args)
        params (sql/fetch-params table-name path args)]
    (query db sql params)))


(defn insert [db table-name params]
  (->> (execute db (sql/insert table-name params) params)
       (last-inserted db table-name)))


# (defn update [db table-name id params])
#   (execute db (sql/update table-name id params))
#   (fetch db table-name id)


# (comment)
#   (insert db :account {:name "name"})
#   (insert-all db :account {:name "name"})
#
#   (update db :account 1 {:name "updated name"})
#   (update-all db :account {:name "name"} {:name "new name"})
#
#   (upsert db :account 1 {:name "updated or inserted name"})
#   (upsert-all db :account {:name "name"} {:name "updated or inserted name"})
#
#   (delete db :account 1)
#   (delete-all db :account {:name "name"})
#
#   (fetch db :account) # => select * from account;
#   (fetch db :account 1) # => select * from account where id = ?
# (fetch db :account 1 :todos 2) # => select * from todo where account_id = :account-id and todo = :todo-id
#
# (q db '[:select *])
#         :from account
#         :where id = ?id and name = ?name
#       {:id 1} # => select * from acount where id = :id and name = :name
#
#
# (defn where-clause [dictionary-params])
#   (let [ks (keys dictionary-params)])
#     (map |(string $ " = :" $)) ks
#
#
# (defn delete [db table-name params])
#   (let [rows (query db (string "select * from " table-name " where " (where-clause params)))])
#     (execute db)
#       (string "delete from " table-name " where " (where-clause params))
#     (first rows)
