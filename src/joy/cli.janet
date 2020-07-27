(import ./cli/migrations :as migrations)
(import ./cli/tables :as tables)
(import ./cli/route :as route)
(import ./cli/controller :as controller)
(import ./cli/projects :as projects)
(import ./env :as env)
(import ./helper :as helper)


(defn generate
  `
  Responsible for creating boilerplate route and migration files

  Example:

  (from the shell)

  joy create migration create-table-accounts
  joy create route accounts

  Or you can create a create table migration with
  some args for column names and types:

  joy create table accounts 'name text not null unique' 'email text not null unique' 'password text not null'
  `
  [& args]
  (let [[kind name] args]
    (case kind
      "migration" (migrations/create name)
      "database" (helper/create-file (env/env :database-url))
      "db" (helper/create-file (env/env :database-url))
      "controller" (controller/create name)
      "route" (route/create name)
      "table" (migrations/create (string "create-table-" name)
                (tables/create (drop 1 args)))
      "project" (projects/generate name))))
