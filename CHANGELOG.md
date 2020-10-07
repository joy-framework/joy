## Joy 0.9.0 (07/26/2020)

Ch-ch-changes!

First, I want to give a shout out to

@goto-engineering for fixing the response duration logging code!
@hammywhammy / @hweeks for all of the hard work on the docker/ci stuff!

- keyword routes
- default middleware function
- before/after functions
- a new, simpler starting template

## keyword routes

Tired of having to define all of your routes in two different files, me too!

```clojure
(route :get "/" :home)

(defn home [r])
```

This is how the new template works too:

```clojure
(route :get "/todos" :todos/index)
(route :get "/todos/new" :todos/new)
(route :get "/todos/:id" :todos/show)
(route :post "/todos" :todos/create)
(route :get "/todos/:id/edit" :todos/edit)
(route :patch "/todos/:id" :todos/patch)
(route :delete "/todos/:id" :todos/delete)
```

You can imagine the corresponding functions.

# default middleware function

Before:

```clojure
(def routes (routes [:get "/" :home]))

(def app (as-> (handler routes) ?
               (layout ? layout/app)
               (csrf-token ?)
               (session ?)
               (extra-methods ?)
               (query-string ?)
               (body-parser ?)
               (server-error ?)
               (x-headers ?)
               (static-files ?)
               (not-found ?)
               (logger ? )))
```

After:

```clojure
(def routes (routes [:get "/" :home]))

(def app (app {:routes routes :layout layout-fn}))
```

You can also turn middleware on/off by changing the dictionary passed to app:

```clojure
(app {:layout false :extra-methods false :session false :x-headers false :static-files false})
```

There are a few more options too like changing the cookie options for sessions, things like that.

# before/after functions

Don't want to bother writing a whole middleware function just to append things to the request on certain routes? Me neither!

```clojure
(before "/*" :run-before)

(defn run-before [req]
  (put req :a 1))
```

You can use a combination of wildcard routes and the before function to modify the request dictionary before any matching routes. Make sure you return the request from your before functions.

Similarly, the `after` function works the same way, except on the response, you also need to return the response as well.

# new starter template

```clojure
.
├── Procfile
├── main.janet
├── project.janet
└── public
    ├── app.css
    └── app.js
```

5 files with a Procfile! One thing I didn't add to the default template is a Dockerfile which I'm kind of fine tuning still, it works great with dokku!

That's it for now, there are a few more new things, but you can find me online anywhere or consult the docs if you want to know more

## Joy 0.8.0 (05/14/2020)

*Warning* Breaking changes ahead, only if you're using the `css`, `js` or `app` functions

I try not to make too many breaking changes, but it's still early days
and hopefully no one was using the js/css bundler stuff.

Also I don't plan on introducing breaking changes EVER after 1.0

In fact my strategy is if I want to break things too much, I will release a whole new repo named joy2.

Let's hope it never comes to that.

## Change script/link functions

Anyway if you were using those functions change this:

```clojure
(css "/style1.css" "/style2.css")
```

to this
```clojure
(link {:href ["/style1.css" "/style2.css"]})
```

and the js is similar:
```clojure
(js "/js1.js" "/js2.js")
```
to:
```clojure
(script {:src ["/js1.js" "/js2.js"]})
```
with the added benefit now of adding other attributes, like `:defer`

## Function routes

Again, this doesn't happen often (or at all) but sometimes a new feature
is just too good to pass up.
If you are using the app function, it has changed to handlers, so this:
```clojure
(app (handler routes1) (handler routes2))
```
is now this:
```clojure
(handlers (handler routes1) (handler routes2))
```
What do you get from this breaking change?

Let me show you something *really* cool:
```clojure
(use joy)

(defn / [request]
  (text/html
    [:h1 "You found joy!"]))

(def app (app))

(server app 9001) # go ahead and visit http://localhost:9001 I dare ya
```
That is all it takes now to get a joy app up and running!

## Joy 0.7.4 (05/14/2020)

More bug fixes and improvements

* 76f19e4 - Bump version 0.7.4
* a860b30 - Use absolute paths for bundles
* b26c7e3 - Only call layout when handler returns a tuple
* 4f98b70 - Attempt to symlink to /usr/local/bin on install

## Joy 0.7.3 (05/14/2020)

Bug fixes and improvements

* 67f1ee2 - Pass :database-url to db/connect
* bd1e98e - Bump to 0.7.3
* 5cb7d6e - Use latest joy in template
* 06b1316 - Remove joy/db import from generated routes
* c918798 - Fix route generation

## Joy 0.7.2 (05/14/2020)

A few bugfixes, notably though, headers are case-insensitive now with a new, handy `headers` function:

```clojure
(header request :x-csrf-token) # or whatever you want
```

Oh! There's also a new `json-body-parser` middleware that parses incoming json requests with a `content-type: application/json` header

## Joy 0.7.1 (05/14/2020)

Tiny release, just fixing up html escaping

## Joy 0.7.0 (05/14/2020)

Notable things in this release:

- Tentative postgresql support via the [db](https://github.com/joy-framework/db) library
- Better logging, where the request is always logged, even if the response isn't
- Routes can now be dynamically found within the `routes/` folder like so:

```clojure
(use joy)

(defroutes routes
  [:get "/" :home/index])
```

Assuming you have a file: `src/routes/home.janet` and then within that file, this code:

```clojure
(defn index [request])
```

- Array body parsing, so you can have inputs in a form like this:

```clojure
[:input {:type "text" :name "tag[]"}]
[:input {:type "text" :name "tag[]"}]
[:input {:type "text" :name "tag[]"}]
```

and on the server you'll have your body look like this:

```clojure
(defn a-post [request]
  (def body (request :body))

  (body :tag)) # => @["tag1" "tag2" "tag3"]
```

- session cookies now default to SameSite=Lax instead of strict
- Lots of other little bugs fixed and improvements made

## Joy 0.6.0 (02/09/2020)

This one was a doozy, but I'm fairly sure there were no breaking changes 🤞

* Add new `rescue-from` fn
* Fix a regression when parsing request bodies, a space would be a + character
* Joy now sets foreign keys and journal_mode to WAL in `with-db-connection`
* DB_NAME is now DATABASE_URL to help with heroku deployments (if there are any)
* Use a `dyn` for the database connection instead of opening/closing a connection on each request
* Fixed a bug where the `server-error` middleware would totally ruin the handler's janet env
* Fixed a bug where when you switch joy apps the cookie decryption would fail and just throw errors
* Changed the default new joy app template

It doesn't seem like a lot, but it is. Here's the gist of it:

Before:

```clojure
(import joy :prefix "")

(defn index [request]
  (let [{:db db} request]
    (fetch-all db [:todos])))
```

Now:

```clojure
(import joy :prefix "")
(import joy/db)

(db/connect)

(defn index [request]
  (db/fetch-all [:todos])))
```

This change sets joy up for it's own console a la `joy console` from the terminal similar to `rails console` which sets up the database connection and lets you mess around with data.

## Joy 0.5.3 (02/03/2020)

### What's new?

* New version of [tester](https://github.com/joy-framework/tester/releases/tag/0.2.1)
* Now uses [janet-uri](https://github.com/andrewchambers/janet-uri) for uri encoding/decoding/parsing
* A little house cleaning with the tests
* A few /docs + docstrings added
* The request map now has the response map inside of it for things like conditional menus when people are logged in, etc.
* [when](https://github.com/joy-framework/joy/commit/922f0bdb7d01fdbd730b4bd218189cfa59ba6c77) is now supported in vector-html
* [base64/encode](https://github.com/joy-framework/joy/commit/0931e9d) now doesn't leave you with a trailing `\0` char
* New [rest](https://github.com/joy-framework/joy/commit/dd50aef) macro
* A new [uri validator](https://github.com/joy-framework/joy/commit/c42ed5d) !

### What's breaking?

#### [label](https://github.com/joy-framework/joy/commit/857582b)

It went from this

```clojure
(label :field-name)
```

to this
```clojure
(label :field-name "label string")
```
 so watch out.

#### [submit](https://github.com/joy-framework/joy/commit/857582b)

This:

```clojure
(submit "save" [:class "red"])
```

to this:

```clojure
(submit "save" :class "red")
```

#### [delete-all](https://github.com/joy-framework/joy/commit/a7909ba326a73ab4b4f4e1e240064e575207dcf7#diff-7533db7c3c5a3ab115aa0d12bc1aa4dfL139)

Also changed, it's now:

```clojure
 (with-db-connection [db "dev.sqlite3"]
    (delete-all db :post :where {:draft true} :limit 1))
```

or

```clojure
(delete-all db :post)
```

Which will **delete all rows** in the `post` table.

## Joy 0.5.2 (01/05/2020)

Check if static files exist in middleware first so they actually return 404s

## Joy 0.5.1 (01/04/2020)

Joy was still using the old version of cipher without jhydro. This fixes that.

## Joy 0.5.0 (01/04/2020)

* Breaking changes for routing
* No more per route middleware
* Delete json-encode/decode functions
* Rely on defglobal for routes tokens
* Handle nil responses in built in middleware
* Simplify routing by using `some` and grouping middleware per handler
* `(defroutes name [] [])` instead of `(def name (routes [] []))`
* Massive anti-csrf changes: encrypting, base64 encoding and storing the token in the session + hidden form fields
* New module for base64 encoding/decoding (base64/encode), (base64/decode)
* `app` has been renamed to `handler`
* `app` is still around but it runs handlers one after the other for different middleware stacks (apis, auth...)

## Joy 0.4.0 (12/16/2019)

* Add git dotfiles to template folder
* Add first pass at code generation
* Change all database interactions to auto kebab-case from and snake-case to db
* Fix duplicate body-parser middleware in template
* Add csrf-protection
* Set path and http-only on set-cookie middleware
* Marshal/unmarshal for cookie session serialization
* Escape html in attributes
* Add second pass at route code generation

## Joy 0.3.0 (12/06/2019) ##

* Finish up the cli
* Add a template folder and the `joy new` command
* Add form, `url-for`, `action-for` and `redirect-to` helpers
* Finish up `*.sql` migrations
* Get static files working
* Stop logging static files by default
* Use `:export` instead of redefining everything in `joy.janet`
* Fix quite a few bugs

## Joy 0.2.0 (11/21/2019) ##

* Add a whole new MIT licensed http server halo

## Joy 0.1.0 (11/01/2019) ##

* Add form validations
* Add db functions

## Joy 0.0.1 (09/02/2019) ##

* Port over env, helper, logger, responder and router code from coast
