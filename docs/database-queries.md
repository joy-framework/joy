# Database Queries

Database queries in joy are very basic, they go a little something like this:

## Connecting to the database

Joy uses the `.env` file in your project dir (the one with the `project.janet` file in it) or your actual os environment variables and looks for `DATABASE_URL` or in joy `(env :database-url)` for the connection string.

```clojure
(import joy)

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

; # or
(def account (db/insert :account {:name "account 1"}))
; # => {:name "account 1" :id 1 ...}

(def account (db/update account {:name "account #1"}))
; # => {:name "account #1" :id 1 ...}
```

This could also be

```clojure
(db/update :account {:id 1} {:name "new name 4"})
```

Getting a row by id

```clojure
(db/fetch [:account 1])

;# or

(db/find :account 1)
```

Getting a row by id with a join

```clojure
(db/fetch [:account 1 :todo 2])
```

Getting several *scoped* rows (with a join)

```clojure
(def account (db/find :account 1))

(db/fetch-all [:account account :todos])

; # or

(db/fetch-all [:account 1 :todos])
```

Deleting a row by id

```clojure
(db/delete :account 1)

; # or
(def account (db/find :account 1))

(db/delete account)
```

Deleting all rows in a table

```clojure
(db/delete-all :account)
```

A more generic query

```clojure
(db/from :account :where {:email "email@example.com"} :order "created_at desc" :limit 10)
```

Find first row by query

```clojure
(db/find-by :account :where {:email "email@example.com"})
```

A few other cool things:

```clojure
(db/from :account
         :join :post
         :where {:email "email@example.com"}
         :limit 1)

; # => [{:name "account #1" :id 1 :post/id 1 :post/title "post #1" ...}
; #     {:name "account #1" :id 1 :post/id 2 :post/title "post #2" ...}]
```

You can also "roll up" a one to many relationship like this:

```clojure
(db/from :account
         :join/many :post
         :where {:email "email@example.com"}
         :limit 1)

; # =>

[{:name "account #1"
  :id 1
  :posts [{:id 1 :post/title "post #1"}
          {:post/title "post #2"}]}]
```

Notice that the "rolled up" key is the plural name of the joined table.

This works the other way too:

```clojure
(db/from :post
         :join/one :account
         :limit 2)

; # =>

[{:id 1
  :name "post #1"
  :account {:id 1 :name "account #1"}}

 {:id 2
  :name "post #2"
  :account {:id 1 :name "account #1"}}]
```

Here, the "rolled up" key is the singular name of the joined table (if it happens to be plural)

This only lets you do an inner join with one table right now, for anything else you'll have to write sql and query it:

```clojure
(db/query (slurp "db/sql/hello.sql")) ; # or whichever way you want
```

## Conventions

There are a few conventions you should follow:

1. Only foreign keys with the same name as the table will work with `:join` stuff
2. Primary keys should be named `id` and be integers
3. Foreign keys should be named `table_id` and also be integers for `db/fetch` to work across tables
