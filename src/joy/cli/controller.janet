(import ../helper :prefix "")
(import ../env :as env)
(import db)
(import spork/path)
(import musty)


(defn template []
  (slurp (path/join (dyn :syspath) "joy" "cli" "controller.txt")))


(defn app-column? [{:name name}]
  (and (not= name "created-at")
       (not= name "updated-at")
       (not= name "id")))


(defn data [t]
  (db/connect (env/env :database-url))

  (def columns (->> (get (db/schema) t)
                    (map |(string/replace (string t ".") "" $))
                    (map kebab-case)
                    (map |(table :name $))))

  (def app-columns (filter app-column? columns))

  {:columns columns
   :app-columns app-columns
   :table t
   :plural (plural t)
   :singular (singular t)})


(defn render [table]
  (musty/render (template) (data table)))


(defn use-line [table]
  (string/format "(use ./routes/%s)" table))


(defn used? [table lines]
  (find |(= (use-line table) $) lines))


(defn new-main [table]
  (def s (slurp "main.janet"))
  (def lines (string/split "\n" s))
  (unless (used? table lines)
    (string/join (array/insert lines 1 (use-line table))
                 "\n")))


(defn create [table]
  (let [route-string (render table)
        _ (os/mkdir "routes") # just in case
        new-filename (path/join "routes" (string table ".janet"))
        new-main (new-main table)]

    (with-file [f new-filename :w]
      (file/write f route-string))

    (when new-main
      (with-file [f1 "main.janet" :w]
        (file/write f1 new-main)))))
