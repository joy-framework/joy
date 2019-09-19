(import ./joy/env :as env)
(import ./joy/logger :as logger)
(import ./joy/responder :as responder)
(import ./joy/helper :as helper)
(import ./joy/html :as html)
(import ./joy/router :as router)
(import ./joy/middleware :as middleware)
(import "lib/circlet" :as circlet)
(import json)
(import sqlite3)

(def env env/env)
(def logger logger/middleware)
(def log logger/log)
(def respond responder/respond)
(def redirect responder/redirect)
(def rescue helper/rescue)
(def select-keys helper/select-keys)
(def html html/render)
(def raw-html html/raw)
(def doctype html/doctype)
(def json-encode json/encode)
(def json-decode json/decode)
(def serve circlet/server)
(def app router/handler)
(def routes router/routes)
(def middleware router/middleware)
(def static-files middleware/static-files)
(def body-parser middleware/body-parser)
(def set-cookie middleware/set-cookie)
(def set-layout middleware/set-layout)
(def server-error middleware/server-error)

(defmacro with-db-connection [binding & body]
  (with-syms [$rows]
   ~(let [,(first binding) (,sqlite3/open ,(get binding 1))
          ,$rows ,(splice body)]
      (,sqlite3/close ,(first binding))
      ,$rows)))

(defn query [db sql &opt args]
  (let [sql (string sql ";")]
    (->> (sqlite3/eval db sql (or args {}))
         (map (partial helper/map-keys keyword)))))

(defn execute [db sql &opt args]
  (default args {})
  (let [sql (string sql ";")]
    (sqlite3/eval db sql args)
    (sqlite3/last-insert-rowid db)))

(defn insert-columns [dictionary-d]
  (->> (keys dictionary-d)
       (map string)))

(defn insert [keyword-table dictionary-params]
  (with-db-connection [db "dev.sqlite3"]
    (let [columns (-> (insert-columns dictionary-params)
                      (string/join ","))
          vals (as-> (insert-columns dictionary-params) %
                     (map (fn [val] (string ":" val)) %)
                     (string/join % ","))
          table-name (string keyword-table)
          id (execute db
              (string "insert into " table-name "(" columns ") values (" vals ")")
              dictionary-params)
          row (first
               (query db (string "select * from " table-name " where rowid = :id") {:id id}))]
      (helper/map-keys keyword row))))

