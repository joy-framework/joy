(declare-project
  :name "%project-name%"
  :description ""
  :dependencies [{:repo "https://github.com/joy-framework/joy" :tag "0.5.2"}
                 {:repo "https://github.com/joy-framework/tester" :tag "0.1.0"}]
  :author ""
  :license ""
  :url ""
  :repo "")

(declare-executable
  :name "%project-name%"
  :entry "src/server.janet")

(phony "server" []
  (do
    (os/shell "pkill -xf 'janet src/server.janet'")
    (os/shell "janet src/server.janet")))

(phony "watch" []
  (do
    (os/shell "pkill -xf 'janet src/server.janet'")
    (os/shell "janet src/server.janet &")
    (os/shell "fswatch -o src | xargs -n1 -I{} ./watch")))

