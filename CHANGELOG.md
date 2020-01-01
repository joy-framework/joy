## Joy 0.5.0 (12/31/2019)

* Breaking changes for routing
* No more per route middleware
* Delete json-encode/decode functions
* Rely on defglobal for routes tokens
* Handle nil responses in built in middleware
* Simplify routing by using `some` and grouping middleware per handler
* `(defroutes name [] [])` instead of `(def name (routes [] []))`
* Massive anti-csrf changes: encrypting, base64 encoding and storing the token in the session + hidden form fields
* New module for base64 encoding/decoding (base64/encode), (base64/decode)

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
