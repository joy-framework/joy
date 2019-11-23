## You Found Joy!

Joy is a full stack web framework written in [janet](https://github.com/janet-lang/janet)

**This project is in early development so expect major changes**

```clojure
(import joy)

(defn home [request]
  (joy/respond :text
    "Have some joy with janet 😇"))

(def routes
  (joy/routes [:get "/" home]))

(def app (joy/app routes))

(joy/serve app 8000)
```

**The below is README driven development, this doesn't work yet**

## Getting Started

First things first, make sure [janet is installed](https://janet-lang.org/docs/index.html)

Second things second, install the joy cli like this

```sh
jpm install https://github.com/joy-framework/joy.git
```

Hopefully the `joy` executable will be on your path and ready to roll. Now, run the following from your terminal

```sh
joy new my-joy-project
```

This should create a new directory called `my-joy-project` and it should create a few files and things
to get you started. Next, let's create a database, two tables and connect them with routes and a few functions for handling requests.

### Create a new sqlite database

If you aren't already in the `my-joy-project` directory, go ahead and get in there. Now run

```sh
joy create db
```

This creates a new empty database named `my-joy-project.sqlite3`. Let's fill it up.

### Create database tables

Run this to create a new table with a few columns:

```sh
joy create table account name:text email:text password:text
```

Let's go ahead and create another table that will store some data for those accounts

```sh
joy create table post title:text body:text account_id:integer
```

This has created two files in your db/migrations folder that are waiting to get applied to the database.

### Run database migrations

Run this from your terminal

```sh
joy migrate db
```

This will output what just happened to your database and create a new file `db/schema.sql` which is really just sqlite3's `.schema` output ... for now.

### Create route files

In joy there is no MVC, no ORMs, no classes, no objects. just functions that take in requests and return responses. Let's make two route files that correspond to the two tables from earlier

```sh
joy create route account
joy create route post
```

Those commands have created two new files: `src/routes/account.janet` and `src/routes/post.janet`

## Why?

I wanted something that felt like coast on clojure but took so little resources I could run dozens (if not hundreds) of websites on a single cheap [VPS]().
