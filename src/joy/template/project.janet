(declare-project
  :name "%project-name%"
  :description ""
  :dependencies [{:repo "https://github.com/joy-framework/joy" :tag "0.5.0"}
                 {:repo "https://github.com/joy-framework/tester" :tag "0.1.0"}]
  :author ""
  :license ""
  :url ""
  :repo "")

(declare-executable
  :name "%project-name%"
  :entry "main.janet")

(phony "server" []
  (do
    (os/shell "pkill -xf 'janet main.janet'")
    (os/shell "janet main.janet")))

(phony "watch" []
  (do
    (os/shell "pkill -xf 'janet main.janet'")
    (os/shell "janet main.janet &")
    (os/shell "fswatch -o src | xargs -n1 -I{} ./watch")))

