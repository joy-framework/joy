(import ../helper :as helper)
(import ../db :as db)


(defn create [table-name]
  (helper/with-file [f "src/joy/cli/routes.txt"]
    (let [template (file/read f :all)]
      (db/with-connection [conn "test.sqlite3"]
        (let [columns (->> (db/query conn "select pti.name as col from sqlite_master join pragma_table_info(sqlite_master.name) pti on sqlite_master.name != pti.name where sqlite_master.name = :table order by pti.cid" {:table table-name})
                           (map |(get $ :col)))
              ks (->> (filter |(and (not= $ "created_at")
                                    (not= $ "updated_at")) columns)
                      (map helper/kebab-case)
                      (map |(string ":" $))
                      (helper/join-string " "))
              dest-ks (->> (map helper/kebab-case columns)
                           (map |(string ":" $ " " $))
                           (helper/join-string " "))
              th-elements (->> (map helper/kebab-case columns)
                               (map |(string/format `[:th "%s"]` $))
                               (helper/join-string
                                (string/format "\n%s"
                                  (string/repeat " " 7))))
              td-elements (->> (map helper/kebab-case columns)
                               (map |(string/format `[:td %s]` $))
                               (helper/join-string
                                (string/format "\n%s"
                                  (string/repeat " " 10))))
              show-th-elements (->> (map helper/kebab-case columns)
                                    (map |(string/format `[:th "%s"]` $))
                                    (helper/join-string
                                     (string/format "\n%s"
                                       (string/repeat " " 6))))
              show-td-elements (->> (map helper/kebab-case columns)
                                    (map |(string/format `[:td %s]` $))
                                    (helper/join-string
                                     (string/format "\n%s"
                                       (string/repeat " " 6))))
              form-elements (->> (map helper/kebab-case columns)
                                 (map |(string/format `[:td %s]` $))
                                 (helper/join-string
                                  (string/format "\n%s"
                                    (string/repeat " " 6))))]
          (print (->> (string/replace-all "%table-name%" table-name template)
                      (string/replace-all "%keys%" ks)
                      (string/replace-all "%destructured-keys%" dest-ks)
                      (string/replace-all "%th-elements%" th-elements)
                      (string/replace-all "%td-elements%" td-elements)
                      (string/replace-all "%show-th-elements%" show-th-elements)
                      (string/replace-all "%show-td-elements%" show-td-elements)
                      (string/replace-all "$form-elements%" form-elements))))))))

