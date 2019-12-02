(import ./joy/env :prefix "" :export true)
(import ./joy/logger :prefix "" :export true)
(import ./joy/responder :as responder)
(import ./joy/helper :as helper)
(import ./joy/html :as html)
(import ./joy/router :as router)
(import ./joy/middleware :as middleware)
(import ./joy/db :as db)
(import ./joy/validator :as validator)
(import ./joy/migrator :as migrator)
(import ./joy/cli :as cli)
(import halo)
(import json)
(import sqlite3)


(def respond responder/respond)
(def render responder/respond)
(def redirect responder/redirect)

(def action-for router/action-for)
(def redirect-to router/redirect-to)

(defmacro rescue [f &opt id]
  ~(try
     [nil ,f]
     ([err]
      (if (and (dictionary? err)
            (or (true? (get err :id))
              (= ,id (get err :id))))
        [(get err :error) nil]
        (error err)))))
(def raise helper/raise)

(def select-keys helper/select-keys)

(def html html/render)
(def raw-html html/raw)
(def doctype html/doctype)

(def json-encode json/encode)
(def json-decode json/decode)

(def serve halo/server)

(def app router/handler)
(def routes router/routes)
(def middleware router/middleware)

(def static-files middleware/static-files)
(def body-parser middleware/body-parser)
(def set-cookie middleware/set-cookie)
(def set-layout middleware/set-layout)
(def server-error middleware/server-error)
(def set-db middleware/set-db)
(def session middleware/session)
(def extra-methods middleware/extra-methods)
(def query-string middleware/query-string)

(def query db/query)
(def execute db/execute)
(def fetch db/fetch)
(def fetch-all db/fetch-all)
(def from db/from)
(def insert db/insert)
(def insert-all db/insert-all)
(def update db/update)
(def update-all db/update-all)
(def delete db/delete)
(def delete-all db/delete-all)

(defmacro with-db-connection
  `A macro that takes a binding array, ex: [conn "x.sqlite3"] and expressions and executes them in the context of the connection.

   Example:

   (import sqlite3)

   (with-db-connection [conn "dev.sqlite3"]
     (sqlite3/eval conn "select 1;" {}))`
  [binding & body]
  ~(with [,(first binding) (,sqlite3/open ,(get binding 1)) ,sqlite3/close]
    ,(splice body)))

(def params validator/params)
(def validates validator/validates)

(def pprint helper/pprint)

(def migrate migrator/migrate)
(def rollback migrator/rollback)

(def create cli/create)
(def drop cli/drop)
