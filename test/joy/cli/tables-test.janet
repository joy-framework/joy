(import tester :prefix "" :exit true)
(import "src/joy/cli/tables" :as tables)

(deftest
  (test "basic create test"
    (= {:up "create table accounts (\n  id integer primary key,\n  email text not null,\n  created_at integer not null default(strftime('%s', 'now')),\n  updated_at integer\n)"
        :down "drop table accounts"}
       (tables/create ["accounts" "email text not null"]))))

