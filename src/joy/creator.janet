# src/joy/creator.janet
(import ./creator/migrations :as migrations)

(defn create
  `Responsible for creating boilerplate route and migration files (and their combo: the "table" generator).
  Ex.

  joy create migration create-table-accounts
  joy create route accounts

  Or the previous two commands can be combined into one along with
  some args for column names and types:

  joy create table accounts name:text email:text password:text`
  [& args]
  (let [[kind name] args]
    (case kind
      "migration" (migrations/create name)
      "route" nil
      "table" nil)))

