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

  (test "insert-all test"
    (= "insert into account (name) values (?), (?)"
       (sql/insert-all :account [{:name "name1"} {:name "name2"}])))

  (test "insert-all test with two params"
    (= "insert into account (email, name) values (?,?), (?,?)"
       (sql/insert-all :account [{:name "name1" :email "email"} {:name "name2" :email "email2"}])))

  (test "insert-all-params test with two params"
    (= ["email" "name1" "email2" "name2"]
       (freeze (sql/insert-all-params [{:name "name1" :email "email"} {:name "name2" :email "email2"}]))))

  (test "insert-all-params test with three params"
    (= [1 "email" "name1" 2 "email2" "name2"]
       (freeze (sql/insert-all-params [{:name "name1" :email "email" :test 1} {:name "name2" :email "email2" :test 2}]))))

  (test "insert-all-params test"
    (= ["name1" "name2"]
       (freeze (sql/insert-all-params [{:name "name1"} {:name "name2"}]))))

  (test "insert-all-params test with nil"
    (= ["name1"]
       (freeze (sql/insert-all-params [{:name "name1"} {:name nil}]))))

  (test "update with dictionary where clause"
    (= "update account set name = :name where id = :id"
       (sql/update :account {:name "name"})))

  (test "update with string where clause"
    (= "update account set name = :name where id = :id"
       (sql/update :account {:name "name"})))

  (test "update with null value"
    (= "update account set name = null where id = :id"
       (sql/update :account {:name 'null})))

  (test "update-all test with same where and set keys"
    (= "update account set name = ? where name = ?"
       (sql/update-all :account {:name "old name"} {:name "new name"})))

  (test "update-all-params test"
    (= ["new name" "old name"]
       (freeze (sql/update-all-params {:name "old name"} {:name "new name"}))))

  (test "delete test"
    (= "delete from account where id = :id"
       (sql/delete :account 1)))

  (test "delete-all test with params dictionary"
    (= "delete from account where name = :name"
       (sql/delete-all :account {:name "name"})))

  (test "delete-all test with params string"
    (= "delete from account where name = :name or name is null"
       (sql/delete-all :account "name = :name or name is null")))

  (test "where-clause test"
    (= "id = :id and name = :name"
       (sql/where-clause {:id 1 :name "name"})))

  (test "where-clause with a null value"
    (= "id = :id and name is null"
       (sql/where-clause {:id 1 :name 'null})))

  (test "from test"
    (= "select * from account where name = :name "
       (sql/from :account {:where {:name "name"}})))

  (test "from with options test"
    (= "select * from account where name = :name order by rowid desc limit 3"
       (sql/from :account {:where {:name "name"} :order "rowid desc" :limit 3})))

  (test "fetch-options test with limit"
    (= "limit 10"
       (sql/fetch-options {:limit 10})))

  (test "fetch-options test with limit and offset"
    (= "limit 10 offset 2"
       (sql/fetch-options {:limit 10 :offset 2})))

  (test "fetch-options test with limit offset and order!"
    (= "order by name desc limit 10 offset 2"
       (sql/fetch-options {:limit 10 :offset 2 :order "name desc"})))

  (test "fetch-options test with limit offset and order asc"
    (= "order by name limit 10 offset 2"
       (sql/fetch-options {:limit 10 :offset 2 :order "name"})))

  (test "fetch-options test with limit offset and order by two args"
    (= "order by name, id desc limit 10 offset 2"
       (sql/fetch-options {:limit 10 :offset 2 :order "name, id desc"})))

  (test "fetch-options test with limit offset and order by with keyword"
    (= "order by name limit 10 offset 2"
       (sql/fetch-options {:limit 10 :offset 2 :order :name})))

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
    (= "select * from account where account.id = ?"
       (sql/fetch [:account 1])))

  (test "fetch test with two tables and one id"
    (= "select * from todo join account on account.id = todo.account_id where account.id = ?"
       (sql/fetch [:account 1 :todo])))

  (test "fetch test with two tables and two ids"
    (= "select * from todo join account on account.id = todo.account_id where account.id = ? and todo.id = ?"
       (sql/fetch [:account 1 :todo 2])))

  (test "fetch test with two tables and two ids"
    (= "select * from todo join account on account.id = todo.account_id where account.id = ? and todo.id = ?"
       (sql/fetch [:account 1 :todo 2])))

  (test "fetch test with three tables and two ids"
    (= "select * from comment join todo on todo.id = comment.todo_id join account on account.id = todo.account_id where account.id = ? and todo.id = ?"
       (sql/fetch [:account 1 :todo 2 :comment])))

  (test "fetch-params test with three tables and two ids"
    (= [1 2]
       (freeze (sql/fetch-params [:account 1 :todo 2 :comment]))))

  (test "fetch-params test with two tables and one id"
    (= [1]
       (freeze (sql/fetch-params [:account 1 :todo]))))

  (test "fetch-params test with no ids"
    (= []
       (freeze (sql/fetch-params [:account]))))


  (test "fetch test with one table and options"
    (= "select * from account limit 10"
       (sql/fetch [:account] {:limit 10})))

  (test "fetch test with one table and limit and offset options"
    (= "select * from account limit 10 offset 2"
       (sql/fetch [:account] {:limit 10 :offset 2}))))
