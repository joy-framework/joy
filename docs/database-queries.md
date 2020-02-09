# Database Queries

Database queries in joy are very basic, they go a little something like this:

## Connecting to the database

Joy uses the `.env` file in your project dir (the one with the `project.janet` file in it) or your actual os environment variables and looks for `DATABASE_URL` or in joy `(env :database-url)` for the connection string.

```clojure
(import joy/db)

(db/connect)
```

That's all that you need to connect to the database

## Basics

Inserting a row

```clojure
(db/insert :account {:name "account 1"})
```

Updating a row by id

```clojure
(db/update :account 1 {:name "new name 4"})
```

This could also be

```clojure
(db/update :account {:id 1} {:name "new name 4"})
```

Getting a row by id

```clojure
(db/fetch [:account 1])
```

Getting a row by id with a join

```clojure
(db/fetch [:account 1 :todo 2])
```

Getting several *scoped* rows (with a join)

```clojure
(let [current-account 1]
  (db/fetch-all [:account current-account :todos]))
```

Deleting a row by id

```clojure
(db/delete :account 1)
```

Deleting all rows in a table

```clojure
(db/delete-all :account)
```

A more generic query

```clojure
(db/from :account :where {:email "email@example.com"} :order "created_at desc" :limit 10)
```

## Conventions

There are a few conventions you should follow:

1. Singular noun table names
2. Primary keys should be named `id` and be integers
3. Foreign keys should be named `table_id` and also be integers for `db/fetch` to work across tables
