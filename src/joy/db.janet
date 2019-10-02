(import sqlite3)
(import ./helper :as helper)

(defmacro with-connection [binding & body]
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

(defn insert [db table-name dictionary-params]
  (let [columns (-> (insert-columns dictionary-params)
                    (string/join ","))
        vals (as-> (insert-columns dictionary-params) %
                   (map (fn [val] (string ":" val)) %)
                   (string/join % ","))
        id (execute db
            (string "insert into " table-name "(" columns ") values (" vals ")")
            dictionary-params)]
    (first
     (query db (string "select * from " table-name " where rowid = :id") {:id id}))))
