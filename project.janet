(declare-project
  :name "joy"
  :description "A full stack janet web framework"
  :dependencies ["https://github.com/janet-lang/json"
                 "https://github.com/joy-framework/tester"]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")


(declare-source
  :source @["src/joy.janet"])
