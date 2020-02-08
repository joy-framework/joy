(import sqlite3)
(import ./helper :as helper)
(import ./db/sql :as sql)
(import ./env :prefix "")

(setdyn :joy/connection nil)

(defn connect [&opt database-url]
  (let [database-url (or database-url
                         (env :database-url))]
    (setdyn :joy/connection (sqlite3/open database-url))
    (let [db (dyn :joy/connection)]
      (sqlite3/eval db "PRAGMA foreign_keys = 1;")
      (sqlite3/eval db "PRAGMA journal_mode=WAL;")
      db)))


(defn disconnect []
  (sqlite3/close (dyn :joy/connection))
  (setdyn :joy/connection nil))


(defmacro with-connection
  `A macro that overrides joy's default global connection

   Example:

   (import sqlite3)
   (import joy/db)

   (db/with-connection "a-different-database.sqlite3"
     (sqlite3/eval "select 1;"))`
  [database-url & body]
  (with-syms [$databaseurl]
    ~(let [,$databaseurl ,database-url
           'db (connect ,$databaseurl)]
       (sqlite3/eval 'db "PRAGMA foreign_keys = 1;")
       (sqlite3/eval 'db "PRAGMA journal_mode=WAL;")
       ,;body
       (sqlite3/close 'db)
       (setdyn :joy/connection (sqlite3/open (env :database-url))))))


(defmacro with-transaction
  `A macro that wraps database statements in a transaction`
  [& body]
  ~(do
     (sqlite3/eval (,dyn :joy/connection) "BEGIN TRANSACTION;")
     (try
       ,;body
       (sqlite3/eval (,dyn :joy/connection) "COMMIT;")
       ([err]
        (sqlite3/eval (,dyn :joy/connection) "ROLLBACK;")
        (error err)))))


(defn kebab-case-keys
  `Converts a dictionary with snake_case_keys to one with kebab-case-keys

  Example:

  (kebab-case-keys @{:created_at "now"}) => @{:created-at "now"}`
  [dict]
  (if (not (dictionary? dict))
    dict
    (as-> dict ?
          (helper/map-keys helper/kebab-case ?)
          (helper/map-keys keyword ?))))


(defn snake-case-keys
  `Converts a dictionary with kebab-case-keys to one with snake_case_keys

  Example:

  (kebab-case-keys @{:created-at "now"}) => @{:created_at "now"}`
  [dict]
  (if (not (dictionary? dict))
    dict
    (as-> dict ?
          (helper/map-keys helper/snake-case ?)
          (helper/map-keys keyword ?))))


(defn query
  `Executes a query against a sqlite database.

  Example:

  (import joy/db)

  (db/query "select * from todos")

  # or

  (db/query "select * from todos where id = :id" {:id 1})

  => [{:id 1 :name "name"} {...} ...]`
  [sql &opt params]
  (default params {})
  (let [sql (string sql ";")
        params (snake-case-keys params)
        db (dyn :joy/connection)]
    (as-> (sqlite3/eval db sql params) ?
          (map kebab-case-keys ?))))


(defn execute
  `Executes a query against a sqlite database.

  The first arg is the sql to execute, the second optional arg is a dictionary
  for any values you want to pass in.

  Example:

  (import joy/db)

  (db/execute "create table todo (id integer primary key, name text)")

  # or

  (db/execute "insert into todo (id, name) values (:id, :name)" {:id 1 :name "name"})

  => Returns the last inserted row id, in this case 1`
  [sql &opt params]
  (default params {})
  (let [sql (string sql ";")
        params (snake-case-keys params)
        db (dyn :joy/connection)]
    (sqlite3/eval db sql params)
    (sqlite3/last-insert-rowid db)))


(defn last-inserted
  `Takes a row id and returns the first record in the table that matches
  and returns the last inserted row from the rowid. Returns nil if a
  row for the rowid doesn't exist.

  Example:

  (import joy/db)

  (db/last-inserted "todo" 1)

  => {:id 1 :name "name"}`
  [table-name rowid]
  (let [params {:rowid rowid}
        sql (sql/from table-name {:where params :limit 1})]
    (as-> (query sql params) ?
          (get ? 0 {}))))


(def schema-sql
  `
  select
    m.name as tbl,
    pti.name as col
  from sqlite_master m
  join pragma_table_info(m.name) pti on m.name != pti.name`)

(defn schema []
  (as-> schema-sql ?
        (query ?)
        (filter |(= "updated_at" (get $ :col)) ?)
        (map |(table (get $ :tbl) (get $ :col)) ?)
        (apply merge ?)))


(defn fetch
  `Takes a path into the db and optional args
   and returns the first row that matches or nil if none exists.

  Example:

  (import joy/db)

  (db/fetch [:todo 1])

  => {:id 1 :name "name"}`
  [path & args]
  (let [args (table ;args)
        sql (sql/fetch path (merge args {:limit 1}))
        params (sql/fetch-params path)]
    (as-> (query sql params) ?
          (get ? 0))))


(defn fetch-all
  `Takes a path into the db and optional args
   and returns all of the rows that match or an empty array if
   no rows match.

  Example:

  (import joy/db)

  (db/fetch-all [:todo 1 :tag] :order "tag_name asc")

  (db/fetch-all [:todo 1] :limit 1 :order "tag_name desc")

  => [{:id 1 :tag-name "tag1"} {:id 2 :tag-name "tag2"}]`
  [path & args]
  (let [sql (sql/fetch path (table ;args))
        params (sql/fetch-params path)]
    (query sql params)))


(defn from
  `Takes an optional db connection, a table name and optional args
   and returns all of the rows that match the query
   or an empty array if no rows match.

  Example:

  (import joy/db)

  (db/from :todo :where {:completed true} :order "name" :limit 2)

  # or

  (db/from :todo :where {:completed true} :order "name desc" :limit 10)

  => [{:id 1 name "name" :completed true} {:id 1 :name "name2" :completed true}]`
  [table-name & args]
  (let [opts (table ;args)
        sql (sql/from table-name opts)
        params (get opts :where {})]
    (query sql params)))


(defn insert
  `Takes an optional db connection, a table name and a dictionary,
  inserts the dictionary as rows/columns into the database
  and returns the inserted row from the database.

  Example:

  (import joy/db)

  (db/insert :todo {:name "name3"})

  => {:id 3 :name "name3" :completed false}`
  [table-name params]
  (let [sql (sql/insert table-name params)]
    (as-> (execute sql params) ?
          (last-inserted table-name ?))))


(defn insert-all
  `Takes an optional db connection, a table name and an array of dictionaries,
   inserts the array into the database and returns the inserted rows.
   All keys must be the same, as it only insert into one table at a time.

  Example:

  (import joy/db)

  (db/insert-all :todo [{:name "name4"} {:name "name5"}])

  => [{:id 4 :name "name4" :completed false} {:id 5 :name "name5" :completed false}]`
  [table-name arr]
  (let [sql (sql/insert-all table-name arr)
        params (sql/insert-all-params arr)]
    (execute sql params)
    (query (string "select * from " (helper/snake-case table-name) " order by rowid limit " (length params)))))


(defn get-id [val]
  (if (dictionary? val)
    (get val :id)
    val))


(defn update
  `Takes an optional db connection, a table name and a dictionary with an :id key OR an id value,
  and a dictionary with the new columns/values to be updated, updates the row in the
  database and returns the updated row.

  Example:

  (import joy/db)

  (db/update :todo 4 {:name "new name 4"})

  (db/update :todo {:id 4} {:name "new name 4"})

  => {:id 4 :name "new name 4" :completed false}`
  [table-name dict-or-id params]
  (let [sql-table-name (helper/snake-case table-name)
        schema (schema)
        params (if (and (dictionary? schema)
                        (= "updated_at" (get schema sql-table-name)))
                 (merge params {:updated-at (os/time)})
                 params)
        sql (sql/update table-name params)
        id (get-id dict-or-id)]
    (execute sql (merge params {:id id}))
    (fetch [table-name id])))


(defn update-all
  `Takes a table name a dictionary representing the where clause
   and a dictionary representing the set clause and updates the rows in the
   database and returns them.

  Example:

  (import joy/db)

  (db/update-all :todo {:completed false} {:completed true})

  => [{:id 1 :completed true} ...]`
  [table-name where-params set-params]
  (let [rows (from table-name :where where-params)
        sql (sql/update-all table-name where-params set-params)
        schema (schema)
        set-params (if (and (dictionary? schema)
                            (= "updated_at" (get schema (helper/snake-case table-name))))
                     (merge set-params {:updated-at (os/time)})
                     set-params)
        params (sql/update-all-params where-params set-params)]
    (execute sql params)
    (from table-name :where (as-> rows ?
                                  (map |(table :id (get $ :id)) ?)
                                  (apply merge ?)))))


(defn delete
  `Takes a table name, a dictionary with an :id key or an id value
   representing the primary key integer row in the database, executes a DELETE and
   returns the deleted row.

  Example:

  (import joy/db)

  (db/delete :todo {:id 1})

  (db/delete :todo 1)

  => {:id 1 :name "name" :completed true}`
  [table-name dict-or-id]
  (let [id (get-id dict-or-id)
        row (fetch [table-name id])
        sql (sql/delete table-name id)
        params {:id id}]
    (execute sql params)
    row))


(defn delete-all
  `Takes a db connection, a table name, and optional args and deletes the corresponding rows.

  Example:

  (import joy/db)

  (db/delete-all :post :where {:draft true} :limit 1)

  (db/delete-all :post) -> deletes all rows

  (db/delete-all :post :where {:draft true}) -> no limit

  => [{:id 1 :title "title" :body "body" :draft true} ...]`
  [table-name & args]
  (let [params (table ;args)
        where-params (get params :where {})
        rows (from table-name ;args)
        sql (sql/delete-all table-name params)]
    (execute sql where-params)
    rows))
