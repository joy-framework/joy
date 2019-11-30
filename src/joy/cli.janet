(import ./cli/migrations :as migrations)
(import ./cli/tables :as tables)
(import ./env :as env)
(import ./helper :as helper)

(defn create
  `Responsible for creating boilerplate route and migration files
  Ex.

  joy create migration create-table-accounts
  joy create route accounts

  Or you can create a create table migration with
  some args for column names and types:

  joy create table accounts 'name text not null unique' 'email text not null unique' 'password text not null'`
  [& args]
  (let [[kind name] args]
    (case kind
      "migration" (migrations/create name)
      "database" (helper/create-file (env/get-var :db-name))
      "db" (helper/create-file (env/get-var :db-name))
      "route" nil
      "table" (migrations/create (string "create-table-" name)
                (tables/create (drop 1 args))))))


(defn drop
  `Drops the database`
  [& args]
  (let [[kind name] args]
    (case kind
      "database" (os/rm (env/get-var :db-name))
      "db" (os/rm (env/get-var :db-name)))))
