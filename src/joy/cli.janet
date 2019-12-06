(import ./cli/migrations :as migrations)
(import ./cli/tables :as tables)
(import ./cli/routes :as routes)
(import ./cli/projects :as projects)
(import ./env :as env)
(import ./helper :as helper)


(defn generate
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
      "database" (helper/create-file (env/env :db-name))
      "db" (helper/create-file (env/env :db-name))
      "route" (routes/create name)
      "table" (migrations/create (string "create-table-" name)
                (tables/create (drop 1 args)))
      "project" (projects/generate name))))
