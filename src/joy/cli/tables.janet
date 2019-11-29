(defn create [args]
  (let [table-name (first args)
        columns (-> (apply array (drop 1 args))
                    (array/insert 0 "id integer primary key")
                    (array/push "created_at integer not null default(strftime('%s', 'now'))")
                    (array/push "updated_at integer"))
        columns-sql (string/join columns ",\n  ")]
    {:up (string/format "create table %s (\n  %s\n)" table-name columns-sql)
     :down (string/format "drop table %s" table-name)}))

