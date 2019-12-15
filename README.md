## You Found Joy!

Joy is a full stack web framework written in [janet](https://github.com/janet-lang/janet)

```clojure
(import joy)

(defn home [request]
  (joy/render :text "Have some joy with janet 😇"))

(def routes (joy/routes [:get "/" home]))

(def app (joy/app routes))

(joy/server app 8000)
```

## Getting Started

First make sure [janet is installed](https://janet-lang.org/docs/index.html)

Next, install the joy cli like this

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

This creates a new empty database named `dev.sqlite3`. Let's fill it up.

### Taking it for a spin

Alright now that we have a project and a sqlite database set up, it's time to test it out in the browser:

```sh
joy server
```

This should start an http server that's listening at http://localhost:8000.

### Create database tables

Run this to create a new migration with a table with a few columns:

```sh
joy create table account 'email text not null unique' 'password text not null'
```

Let's go ahead and create another table that will store some data for those accounts

```sh
joy create table post 'title text' 'body text' 'account_id integer'
```

This has created two files in your db/migrations folder that are waiting to get applied to the database.

### Run database migrations

Run this from your terminal

```sh
joy migrate
```

This will output what just happened to your database and create a new file `db/schema.sql` which is really just sqlite3's `.schema` output ... for now.

### Create route files

In joy there is no MVC, no ORMs, no classes, and no objects. Just functions that take in requests and return responses. Let's make two route files that correspond to the two tables from earlier

```sh
joy create route account
joy create route post
```

Those commands have created two new files: `src/routes/account.janet` and `src/routes/post.janet`

You can look at them if you want but it's better to try them out. Head back over to http://localhost:8000/accounts
or http://localhost:8000/posts and check it out!

Joy can do a lot more than that, more docs coming soon!

## Why?

I wanted something that felt like [coast](https://coastonclojure.com) but took so little resources (memory + cpu) I could run dozens (if not hundreds) of websites on a single cheap [VPS](https://www.vultr.com/?ref=7614094).
