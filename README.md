## You Found Joy!

Joy is a full stack web framework written in [janet](https://github.com/janet-lang/janet)

```clojure
(use joy)

(route :get "/" :home)
(defn home [request]
  (text/plain "You found joy!"))

(def app (app))

(server app 9001)
```

## Getting Started

First make sure [janet is installed](https://janet-lang.org/docs/index.html)

Next, install the joy cli like this

```sh
jpm install joy
```

Hopefully the `joy` executable will be on your path and ready to roll. If it isn't and you're like me and use homebrew, add this to your `.zprofile`:

```sh
export PATH=/usr/local/Cellar/janet/<your janet version here>/bin:$PATH
```

Then make sure you reload the profile:

```sh
source ~/.zprofile
```

Now, run the following from your terminal

```sh
joy new my-joy-project
```

This should create a new directory called `my-joy-project` and it should create a few files and things
to get you started. 

### Taking it for a spin

Now that we have a project set up, it's time to test it out in the browser:

```sh
joy server
```

This should start an http server that's listening at http://localhost:9001.

Next, let's create a database, a table and connect it with routes and a few functions for handling requests.

### Create a new sqlite database

If you aren't already in the `my-joy-project` directory, go ahead and get in there. Now run

```sh
joy create db
```

This creates a new empty database named `dev.sqlite3`. 

The default template doesn't assume you want a database so you'll need to connect to it in `main.janet`:

```clojure
; # main.janet

(defn main [& args]
  (db/connect (env :database-url))
  (server app (env :port))
  (db/disconnect))
```

### Create a database table

Run this to create a new migration with a table with a few columns:

```sh
joy create table account 'email text unique not null' 'password text not null'
```

This has created one file in your db/migrations folder that is waiting to get applied to the database.

### Run database migrations

Run this from your terminal

```sh
joy migrate
```

This will migrate your database and create a new file `db/schema.sql`

### Generate helpful routes

In joy there are no ORMs, no classes, and no objects, just functions that take requests and return responses.

Let's generate a few routes for the table from earlier:

```sh
joy create controller account
```

Those commands have created another new file: `routes/account.janet` and updated your `main.janet` file with an import statement so the account routes get set up.

Go ahead and check out the new `account` routes in the browser now: `http://localhost:9001/accounts`

Joy can do a lot more than that, [check out the docs here](https://github.com/joy-framework/joy/blob/master/docs/readme.md)

## Why?

I wanted something that felt like [coast](https://coast.swlkr.com) but took so little resources (memory + cpu) I could run dozens (if not hundreds) of websites on a cheap [VPS](https://www.vultr.com/?ref=7614094).

## Docker/Docker Compose

In order to make using joy more portable, we wanted to include a Dockerfile that creates an easy place for you to mount your code in and run joy without having to install anything or manage permissions on your local.
