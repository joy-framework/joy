(import sqlite3)
(import ./helper :as helper)
(import ./db/sql :as sql)


(defmacro with-db-connection
  `A macro that takes a binding array, ex: [conn "x.sqlite3"] and expressions and executes them in the context of the connection.

   Example:

   (import sqlite3)
   (import ./db)

   (db/with-db-connection [conn "dev.sqlite3"]
     (sqlite3/eval conn "select 1;" {}))`
  [binding & body]
  ~(with [,(first binding) (,sqlite3/open ,(get binding 1)) ,sqlite3/close]
    ,;body))


(defn kebab-case-keys
  `Converts a dictionary with snake_case_keys to one with kebab-case-keys

  Example:

  (kebab-case-keys @{:created_at "now"}) => @{:created-at "now"}`
  [dict]
  (->> (helper/map-keys helper/kebab-case dict)
       (helper/map-keys keyword)))


(defn snake-case-keys
  `Converts a dictionary with kebab-case-keys to one with snake_case_keys

  Example:

  (kebab-case-keys @{:created-at "now"}) => @{:created_at "now"}`
  [dict]
  (->> (helper/map-keys helper/snake-case dict)
       (helper/map-keys keyword)))


(defn query
  `Executes a query against a sqlite database. Takes two required parameters
   and one optional dictionary parameter. The first two parameters
   are the database connection, which could either be a dictionary with a
   :connection key or a connection from with-db-connection OR sqlite3/open

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (query db "select * from todos where id = :id" {:id 1}))

  => [{:id 1 :name "name"} {...} ...]`
  [db sql &opt params]
  (default params {})
  (let [connection (if (dictionary? db)
                     (get db :connection)
                     db)
        sql (string sql ";")
        params (if (dictionary? params)
                 (snake-case-keys params)
                 params)]
    (->> (sqlite3/eval connection sql params)
         (map kebab-case-keys))))


(defn execute
  `Executes a query against a sqlite database. Takes two required parameters
   and one optional dictionary parameter. The first two parameters
   are the database connection, which could either be a dictionary with a
   :connection key or a connection from with-db-connection OR sqlite3/open

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (execute db "insert into todo (id, name) values (:id, :name)" {:id 1 :name "name"}))

  => Returns the last inserted row id, in this case 1`
  [db sql &opt params]
  (default params {})
  (let [connection (if (dictionary? db)
                     (get db :connection)
                     db)
        sql (string sql ";")
        params (if (dictionary? params)
                (snake-case-keys params)
                params)]
    (sqlite3/eval connection sql params)
    (sqlite3/last-insert-rowid connection)))


(defn last-inserted
  `Takes a row id and returns the first record in the table that matches
   and returns the last inserted row from the rowid. Returns nil if a
   row for the rowid doesn't exist.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (last-inserted db "todo" 1))

  => {:id 1 :name "name"}`
  [db table-name rowid]
  (let [params {:rowid rowid}
        sql (sql/from table-name {:where params :limit 1})]
    (-> (query db sql params)
        (get 0))))


(defn fetch
  `Takes a db connection, a path into the db and optional args
   and returns the first row that matches or nil if none exists.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (fetch db [:todo 1]))

  => {:id 1 :name "name"}`
  [db path & args]
  (let [args (apply table args)
        sql (sql/fetch path (merge args {:limit 1}))
        params (sql/fetch-params path)]
    (-> (query db sql params)
        (get 0))))


(defn fetch-all
  `Takes a db connection, a path into the db and optional args
   and returns all of the rows that match or an empty array if
   no rows match.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (fetch-all db [:todo 1 :tag] {:order "tag_name asc"}))

  => [{:id 1 :tag-name "tag1"} {:id 2 :tag-name "tag2"}]`
  [db path & args]
  (let [sql (sql/fetch path (apply table args))
        params (sql/fetch-params path)]
    (query db sql params)))


(defn from
  `Takes a db connection, a table name and optional args
   and returns all of the rows that match the query
   or an empty array if no rows match.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (from db :todo :where {:completed true} :order "name" :limit 2))

  => [{:id 1 name "name" :completed true} {:id 1 :name "name2" :completed true}]`
  [db table-name & args]
  (let [opts (apply table args)
        sql (sql/from table-name opts)
        params (get opts :where {})]
    (query db sql params)))


(defn insert
  `Takes a db connection, a table name and a dictionary,
   inserts the dictionary as rows/columns into the database
   and returns the inserted row from the database.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (insert db :todo {:name "name3"}))

  => {:id 3 :name "name3" :completed false}`
  [db table-name params]
  (let [sql (sql/insert table-name params)]
    (->> (execute db sql params)
         (last-inserted db table-name))))


(defn insert-all
  `Takes a db connection, a table name and an array of dictionaries,
   inserts the array into the database and returns the inserted rows.
   All keys must be the same, as it only insert into one table at a time.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (insert-all db :todo [{:name "name4"} {:name "name5"}]))

  => [{:id 4 :name "name4" :completed false} {:id 5 :name "name5" :completed false}]`
  [db table-name arr]
  (let [sql (sql/insert-all table-name arr)
        params (sql/insert-all-params arr)]
    (execute db sql params)
    (query db (string "select * from " (helper/snake-case table-name) " order by rowid limit " (length params)))))


(defn update
  `Takes a db connection, a table name and a dictionary with an :id key OR an id value,
   and a dictionary with the new columns/values to be updated, updates the row in the
   database and returns the updated row.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (update db :todo {:id 4} {:name "new name 4"}))

   # or (update db :todo 4 {:name "new name 4"})

  => {:id 4 :name "new name 4" :completed false}`
  [db table-name dict-or-id params]
  (let [schema (when (dictionary? db)
                 (get db :schema))
        params (if (and (dictionary? schema)
                        (= "updated_at" (get schema (helper/snake-case table-name))))
                 (merge params {:updated-at (os/time)})
                 params)
        sql (sql/update table-name params)
        id (if (dictionary? dict-or-id)
             (get dict-or-id :id)
             dict-or-id)]
    (execute db sql (merge params {:id id}))
    (fetch db [table-name id])))


(defn update-all
  `Takes a db connection, a table name a dictionary representing the where clause
   and a dictionary representing the set clause and updates the rows in the
   database and returns them.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (update db :todo {:completed false} {:completed true}))

  => [{:id 1 :completed true} ...]`
  [db table-name where-params set-params]
  (let [rows (from db table-name where-params)
        sql (sql/update-all table-name where-params set-params)
        schema (when (dictionary? db)
                 (get db :schema))
        set-params (if (and (dictionary? schema)
                            (= "updated_at" (get schema (helper/snake-case table-name))))
                     (merge set-params {:updated-at (os/time)})
                     set-params)
        params (sql/update-all-params where-params set-params)]
    (execute db sql params)
    (from db table-name (map |(table :id (get $ :id))
                          rows))))


(defn delete
  `Takes a db connection, a table name, a dictionary with an :id key or an id value
   representing the primary key integer row in the database, executes a DELETE and
   returns the deleted row.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (delete db :todo {:id 1}))

   # or (delete db :todo 1)

  => {:id 1 :name "name" :completed true}`
  [db table-name dict-or-id]
  (let [id (if (dictionary? dict-or-id)
             (get dict-or-id :id)
             dict-or-id)
        row (fetch db [table-name id])
        sql (sql/delete table-name id)
        params {:id id}]
    (execute db sql params)
    row))


(defn delete-all
  `Takes a db connection, a table name, and optional args and deletes the corresponding rows.

  Example:

  (import joy :prefix "")

  (with-db-connection [db "dev.sqlite3"]
   (delete-all db :post :where {:draft true} :limit 1))

   # or (delete-all db :post) -> deletes all rows
   # or (delete-all db :post :where {:draft true}) -> no limit

  => [{:id 1 :title "title" :body "body" :draft true} ...]`
  [db table-name & args]
  (let [rows (from db table-name ;args)
        params (table ;args)
        sql (sql/delete-all table-name params)]
    (execute db sql (get params :where {}))
    rows))