(declare-project
  :name "%project-name%"
  :description ""
  :dependencies ["https://github.com/joy-framework/joy"]
  :author ""
  :license ""
  :url ""
  :repo "")

(phony "server" []
  (os/shell "janet main.janet"))

(phony "watch" []
  (os/shell "find . -name '*.janet' | entr -r -d janet main.janet"))
