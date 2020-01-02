(import ../helper :as helper)
(import ../db :as db)
(import ../env :as env)
(import path)


(defn join-lines [dict lines]
  (string/join lines
    (string/format "\n%s"
      (string/repeat " " (get dict :spaces)))))


(defn form-destructured-keys [columns]
  (->> (map helper/kebab-case columns)
       (map |(string ":" $ " " $))
       (helper/join-string " ")))


(defn form-element [table-name column]
  (join-lines {:spaces 6}
   [(string/format "(label :%s)" column)
    (string/format "(text-field %s :%s)" table-name column)]))


(defn form-elements [table-name columns]
  (let [elements (->> (map helper/kebab-case columns)
                      (map |(form-element table-name $))
                      (join-lines {:spaces 6}))]
    (string/format "%s\n%s(submit \"Save\")" elements (string/repeat " " 6))))


(defn route-string [table-name]
  (let [sys-path (dyn :syspath)]
    (helper/with-file [f (path/join sys-path "joy" "cli" "routes.txt")]
      (let [template (file/read f :all)]
        (db/with-db-connection [conn (env/env :db-name)]
          (let [columns (->> (db/query conn `select pti.name as col
                                             from sqlite_master
                                             join pragma_table_info(sqlite_master.name) pti on sqlite_master.name != pti.name
                                             where sqlite_master.name = :table order by pti.cid`
                                            {:table table-name})
                             (map |(get $ :col)))
                no-timestamp-columns (filter |(and (not= $ "created_at") (not= $ "updated_at"))
                                             columns)
                not-sys-columns (filter |(and (not= $ "created_at") (not= $ "updated_at") (not= $ "id"))
                                        columns)
                permit-keys (->> (map |(string ":" $) not-sys-columns)
                                 (helper/join-string " "))
                kebab-columns (map helper/kebab-case columns)
                ks (->> (map helper/kebab-case no-timestamp-columns)
                        (map |(string ":" $))
                        (helper/join-string " "))
                dest-ks (->> (map |(string ":" $ " " $) kebab-columns)
                             (helper/join-string " "))
                th-elements (->> (map |(string/format `[:th "%s"]` $) kebab-columns)
                                 (join-lines {:spaces 7}))
                td-elements (->> (map |(string/format `[:td %s]` $) kebab-columns)
                                 (join-lines {:spaces 10}))
                show-th-elements (->> (map |(string/format `[:th "%s"]` $) kebab-columns)
                                      (join-lines {:spaces 6}))
                show-td-elements (->> (map |(string/format `[:td %s]` $) kebab-columns)
                                      (join-lines {:spaces 6}))]
            (->> (string/replace-all "%table-name%" table-name template)
                 (string/replace-all "%keys%" ks)
                 (string/replace-all "%permit-keys%" permit-keys)
                 (string/replace-all "%destructured-keys%" dest-ks)
                 (string/replace-all "%th-elements%" th-elements)
                 (string/replace-all "%td-elements%" td-elements)
                 (string/replace-all "%show-th-elements%" show-th-elements)
                 (string/replace-all "%show-td-elements%" show-td-elements)
                 (string/replace-all "%form-elements%" (form-elements table-name not-sys-columns))
                 (string/replace-all "%form-destructured-keys%" (form-destructured-keys not-sys-columns)))))))))


(defn route-def [table-name]
  (let [plural-name table-name
        singular-name table-name
        sys-path (dyn :syspath)]
    (helper/with-file [f (path/join sys-path "joy" "cli" "route-def.txt")]
      (let [str (file/read f :all)]
        (->> (string/replace-all "%plural-name%" plural-name str)
             (string/replace-all "%singular-name%" singular-name))))))


(defn new-routes-text [table-name]
  (helper/with-file [f "src/routes.janet" :r]
    (let [routes-str (file/read f :all)
          lines (string/split "\n" routes-str)
          imports (filter |(string/has-prefix? "(import" $) lines)
          import-index (length imports)
          lines (array/insert lines import-index (string/format "(import ./routes/%s :as %s)" table-name table-name))
          lines (array/push lines (route-def table-name))]
      (string/join lines "\n"))))


(defn create [table-name]
  (let [route-string (route-string table-name)
        new-filename (path/join "src" "routes" (string table-name ".janet"))
        new-routes-text (new-routes-text table-name)]
    (helper/with-file [f new-filename :w]
      (file/write f route-string))
    (helper/with-file [f1 "src/routes.janet" :w]
      (file/write f1 new-routes-text))))

