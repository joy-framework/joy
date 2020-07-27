(import ./cli/migrations :as migrations)
(import ./cli/tables :as tables)
(import ./cli/route :as route)
(import ./cli/controller :as controller)
(import ./cli/projects :as projects)
(import ./env :as env)
(import ./helper :as helper)

(def usage
  ```joy create [action]

    Actions:
      migration <name>    - Create a new database migration
      db|database <name>  - Create a new sqlite or postgres database
      controller <name>   - Create a new database backed routes file
      page|route <name>   - Add a blank route to the pages route file
      table <name>        - Create a new database migration with a create table statement
  ```)

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
      "page" (route/create name)
      "table" (migrations/create (string "create-table-" name)
                (tables/create (drop 1 args)))
      "project" (projects/generate name)
      (print usage))))
