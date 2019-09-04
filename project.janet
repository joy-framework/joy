(declare-project
  :name "joy"
  :description "A full stack janet web framework"
  :dependencies [{:repo "https://github.com/janet-lang/json.git" :tag "fc59d46f06501569c21d18fff3df15e1494bf144"}
                 {:repo "https://github.com/janet-lang/circlet" :tag "980edbf6dee2021d02a717e03da3a6b7594d51f7"}
                 {:repo "https://github.com/joy-framework/tester" :tag "c14aff3591cb0aed74cba9b54d853cf0bf539ecb"}]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")


(declare-source
  :source @["src/joy.janet"])
