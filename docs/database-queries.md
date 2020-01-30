# Database Queries

Database queries in joy are very basic, they go a little something like this:

## Basics

Inserting a row

```clojure
(import joy)

(joy/with-db-connection [db "dev.sqlite3"]
  (joy/insert :account {:name "account 1"}))
```

Updating a row

```clojure
(joy/with-db-connection [db "dev.sqlite3"]
 (joy/update db :account 1 {:name "new name 4"}))
```

Getting a row by id

```clojure
(joy/with-db-connection [db "dev.sqlite3"]
  (joy/fetch db [:account 1]))
```

Deleting a row

```clojure
(joy/with-db-connection [db "dev.sqlite3"]
  (joy/delete db :account 1]))
```

## Conventions

There are a few conventions you should follow:

1. Singular noun table names
2. Primary keys should be named `id` and be integers
3. Foreign keys should be named `table_id` and also be integers for fetch to work across tables
