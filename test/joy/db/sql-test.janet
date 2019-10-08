(import tester :prefix "" :exit true)
(import "src/joy/db/sql" :as sql)

(deftest
  (test "insert should return a sql string"
    (= "insert into account (name) values (:name)"
       (sql/insert :account {:name "name"})))

  (test "insert with multiple params"
    (= "insert into account (password, name) values (:password, :name)"
       (sql/insert :account {:name "name" :password "password"})))

  (test "insert with 'null param"
    (= "insert into account (name) values (:name)"
       (sql/insert :account {:name 'null})))

  (test "update with dictionary where clause"
    (= "update account set name = :name where id = :id"
       (sql/update :account {:name "name"} {:id 1})))

  (test "update with string where clause"
    (= "update account set name = :name where name like '%joy'"
       (sql/update :account {:name "name"} "name like '%joy'")))

  (test "update with null value"
    (= "update account set name = null where id = :id"
       (sql/update :account {:name 'null} {:id 1})))

  (test "where-clause test"
    (= "id = :id and name = :name"
       (sql/where-clause {:id 1 :name "name"})))

  (test "where-clause with a null value"
    (= "id = :id and name is null"
       (sql/where-clause {:id 1 :name 'null})))

  (test "from test"
    (= "select * from account where name = :name"
       (sql/from :account {:name "name"})))

  (test "fetch-options test with limit"
    (= "limit 10"
       (sql/fetch-options [:limit 10])))

  (test "fetch-options test with limit and offset"
    (= "limit 10 offset 2"
       (sql/fetch-options [:limit 10 :offset 2])))

  (test "fetch-options test with limit offset and order!"
    (= "order by name desc limit 10 offset 2"
       (sql/fetch-options [:limit 10 :offset 2 :order "name desc"])))

  (test "fetch-options test with limit offset and order asc"
    (= "order by name limit 10 offset 2"
       (sql/fetch-options [:limit 10 :offset 2 :order "name"])))

  (test "fetch-options test with limit offset and order by two args"
    (= "order by name, id desc limit 10 offset 2"
       (sql/fetch-options [:limit 10 :offset 2 :order "name, id desc"])))

  (test "fetch-options test with limit offset and order by with keyword"
    (= "order by name limit 10 offset 2"
       (sql/fetch-options [:limit 10 :offset 2 :order :name])))

  (test "clone-inside with one arg"
    (= [:a]
       (freeze (sql/clone-inside [:a]))))

  (test "clone-inside with two args"
    (= [:a :b]
       (freeze (sql/clone-inside [:a :b]))))

  (test "clone-inside with three args"
    (= [:a :b :b :c]
       (freeze (sql/clone-inside [:a :b :c]))))

  (test "join test"
    (= "join account on account.id = todo.account_id"
       (sql/join [:account :todo])))

  (test "fetch joins test with two tables"
    (= "join account on account.id = todo.account_id"
       (sql/fetch-joins [:account :todo])))

  (test "fetch joins test with three tables"
    (= "join todo on todo.id = comment.todo_id join account on account.id = todo.account_id"
       (sql/fetch-joins [:account :todo :comment])))

  (test "fetch test with one table no ids"
    (= "select * from account"
       (sql/fetch [:account])))

  (test "fetch test with one table and one id"
    (= "select * from account where account.id = :account.id"
       (sql/fetch [:account 1])))

  (test "fetch test with two tables and one id"
    (= "select * from todo join account on account.id = todo.account_id where account.id = :account.id"
       (sql/fetch [:account 1 :todo])))

  (test "fetch test with two tables and two ids"
    (= "select * from todo join account on account.id = todo.account_id where account.id = :account.id and todo.id = :todo.id"
       (sql/fetch [:account 1 :todo 2])))

  (test "fetch test with two tables and two ids"
    (= "select * from todo join account on account.id = todo.account_id where account.id = :account.id and todo.id = :todo.id"
       (sql/fetch [:account 1 :todo 2])))

  (test "fetch test with three tables and two ids"
    (= "select * from comment join todo on todo.id = comment.todo_id join account on account.id = todo.account_id where account.id = :account.id and todo.id = :todo.id"
       (sql/fetch [:account 1 :todo 2 :comment])))

  (test "fetch test with one table and options"
    (= "select * from account limit 10"
       (sql/fetch [:account]
         :limit 10)))

  (test "fetch test with one table and limit and offset options"
    (= "select * from account limit 10 offset 2"
       (sql/fetch [:account]
         :limit 10 :offset 2))))
