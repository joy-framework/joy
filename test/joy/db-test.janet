(import tester :prefix "" :exit true)
(import "src/joy/db" :as db)

(db/connect)

(defn last-id []
  (as-> (db/from :account :order "created_at desc" :limit 1) ?
        (get ? 0)
        (get ? :id)))

(deftest
  (test "insert"
    (let [account (db/insert :account {:name "name" :email "test@example.com" :password "password"})]
      (true? (truthy? (get account :created-at)))))

  (test "update"
    (let [account (db/update :account (last-id) {:name "new name"})]
      (= "new name" (get account :name))))

  (test "fetch"
    (let [account (db/fetch [:account (last-id)])]
      (= "new name" (get account :name))))

  (test "fetch-all"
    (let [rows (db/fetch-all [:account] :where {:id (last-id)} :order "created_at desc" :limit 1)]
      (= "new name" (as-> rows ?
                          (get ? 0)
                          (get ? :name)))))

  (test "from"
    (let [rows (db/from :account :where {:id (last-id)})]
      (= "new name" (as-> rows ?
                          (get ? 0)
                          (get ? :name)))))

  (test "delete"
    (let [account (db/delete :account (last-id))]
      (= "new name" (get account :name)))))

(db/delete-all :account)

(db/disconnect)
