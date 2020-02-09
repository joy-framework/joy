# Database Migrations

Database migrations in joy don't stray from other web frameworks. If it ain't broke, right?

## Creating a database

Joy uses the `.env` file (or your system's environment) to create a new sqlite3 database file. So if `.env` has `DATABASE_URL=dev.sqlite3`. Your database will be called `dev.sqlite3`.

```sh
joy create db
```

## Creating a table

Database migrations are not in janet (yet), they are in SQL, which keeps the amount of migration code in the framework low and it's kind of nice to have common SQL generated:

```sh
joy create table person 'email text unique not null' 'password text not null'
```

This will create a new sql file with a timestamp in your `db/migrations` folder and it will look something like this:

```sql
-- up
create table person (
  id integer primary key,
  email text unique not null,
  password text not null,
  created_at integer not null default(strftime('%s', 'now')),
  updated_at integer
);

-- down
drop table account;
```

## Migrating the database

```sh
joy migrate
```

This will run all of the pending migrations (the ones not found in the `schema_migrations` table) against the database.

## Creating an empty migration

```sh
joy create migration
```

## Rolling back

This will rollback one migration at a time

```sh
joy rollback
```
