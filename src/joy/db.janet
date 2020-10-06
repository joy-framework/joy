(import db)


(defn db/save [arg]
  (let [set-attrs (-> (table ;(kvs arg))
                      (put :db/errors nil)
                      (put :db/table nil))

        insert-attrs (-> (table ;(kvs arg))
                         (put :db/errors nil))]

    (if (arg :db/errors)
      arg
      (let [row (db/insert insert-attrs
                           :on-conflict :id
                           :do :update
                           :set set-attrs)]
         (merge row {:db/saved true})))))


(defn saved? [arg]
  (true? (get arg :db/saved)))


(defn errors [arg]
  (get arg :db/errors))
