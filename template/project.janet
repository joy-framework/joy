(declare-project
  :name "%project-name%"
  :description ""
  :dependencies [{:repo "https://github.com/joy-framework/joy" :tag "f3ecb7d2bd7d7d7f0fee7c69808e5b0e7d78f9ee"}
                 {:repo "https://github.com/joy-framework/tester" :tag "c14aff3591cb0aed74cba9b54d853cf0bf539ecb"}]
  :author ""
  :license ""
  :url ""
  :repo "")

(declare-executable
  :name "%project-name%"
  :entry "main.janet")

(phony "server" []
  (os/shell "janet main.janet"))

