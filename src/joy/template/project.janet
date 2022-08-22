(declare-project
  :name "{{project-name}}"
  :description ""
  :dependencies ["https://github.com/joy-framework/joy"
                 "https://github.com/janet-lang/sqlite3"]
  :author ""
  :license ""
  :url ""
  :repo "")

(phony "server" []
  (if (and
       (= "development" (os/getenv "JOY_ENV"))
       (zero? (os/shell "command -v entr &> /dev/null")))
    (os/shell "find . -name '*.janet' | entr janet main.janet")
    (os/shell "janet main.janet")))

(declare-executable
  :name "app"
  :entry "main.janet")
