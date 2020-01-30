# Getting Started

First make sure [janet is installed](https://janet-lang.org/docs/index.html)

Next, install the joy cli like this

```sh
jpm install joy
```

Hopefully the `joy` executable will be on your path and ready to roll. Now, run the following from your terminal

```sh
joy new my-joy-project
```

This should create a new directory called `my-joy-project` and it should create a few files and things
to get you started. Next, let's create a database, a table and connect it with routes and a few functions for handling requests.

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

### Create a database table

Run this to create a new migration with a table with a few columns:

```sh
joy create table account 'email text not null unique' 'password text not null'
```

This has created one file in your db/migrations folder that is waiting to get applied to the database.

### Run database migrations

Run this from your terminal

```sh
joy migrate
```

This will output what just happened to your database and create a new file `db/schema.sql`.

### Create a route file

In joy there are no ORMs, no classes, and no objects, just functions that take in requests and return responses.

Let's make a route file that corresponds to the table from earlier

```sh
joy create route account
```

Those commands have created another new file: `src/routes/account.janet` and updated your `src/routes.janet` file with a few helpful routes.

Go ahead and check out the new `account` routes in the browser now: `http://localhost:8000/account`