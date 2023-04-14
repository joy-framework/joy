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
  (os/shell "janet main.janet"))

(declare-executable
  :name "app"
  :entry "main.janet")
