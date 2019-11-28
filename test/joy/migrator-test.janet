(import tester :prefix "" :exit true)
(import "src/joy/migrator" :as migrator)

(deftest
  (test "parse-migration"
    (= {:up "up sql\nwith a newline"
        :down "down sql\nwith a newline"}
       (migrator/parse-migration "-- up\nup sql\nwith a newline\n-- down\ndown sql\nwith a newline")))

  (test "pending-migrations"
    (= ["20191225000000-x-y-z.sql"]
       (freeze
         (migrator/pending-migrations [] {"20191225000000" "20191225000000-x-y-z.sql"})))))
