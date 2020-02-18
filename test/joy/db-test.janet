(import tester :prefix "" :exit true)
(import "src/joy" :prefix "")
(import cipher)

# create a test .env file when this test is run
(with-file [f ".env" :w]
  (file/write f (string/format "ENCRYPTION_KEY=%s\nJOY_ENV=development\nDATABASE_URL=test.sqlite3" (string (cipher/encryption-key)))))

(db/connect)

(db/delete-all :account)

(defn last-id []
  (as-> (db/from :account :order "created_at desc" :limit 1) ?
        (get ? 0)
        (get ? :id)))

(deftest
  (test "insert"
    (let [account (db/insert :account {:name "name" :email "test@example.com" :password "password"})]
      (true? (truthy? (get account :created-at)))))

  (test "from with null param"
    (let [rows (db/from :account :where {:updated-at 'null})]
      (= 1 (length rows))))

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

  (test "find"
    (let [row (db/find :account (last-id))]
      (= "new name" (get row :name))))

  (test "find-by"
    (let [row (db/find-by :account :where {:id (last-id)})]
      (= "new name" (get row :name))))

  (test "delete"
    (let [account (db/delete :account (last-id))]
      (= "new name" (get account :name)))))

(db/delete-all :account)

(db/disconnect)
