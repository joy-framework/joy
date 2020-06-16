(declare-project
  :name "%project-name%"
  :description ""
  :dependencies ["https://github.com/joy-framework/joy"]
  :author ""
  :license ""
  :url ""
  :repo "")

(phony "server" []
  (os/shell "janet app.janet"))

(phony "watch" []
  (os/shell "fswatch -o . --exclude='.git' --exclude='.sqlite3' | xargs -n1 -I{} ./watch"))
