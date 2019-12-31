(declare-project
  :name "joy"
  :description "A full stack janet web framework"
  :dependencies [{:repo "https://github.com/janet-lang/json" :tag "fc59d46f06501569c21d18fff3df15e1494bf144"}
                 {:repo "https://github.com/janet-lang/sqlite3" :tag "a3a254003c605cf4e048963feda70a60537057d9"}
                 {:repo "https://github.com/janet-lang/path" :tag "d8619960d428c45ebb784600771a7c584ae49431"}
                 {:repo "https://github.com/joy-framework/tester" :tag "c14aff3591cb0aed74cba9b54d853cf0bf539ecb"}
                 {:repo "https://github.com/joy-framework/cipher" :tag "df734c73a8252d3ca6857639e500ba97ef29951b"}
                 {:repo "https://github.com/joy-framework/codec" :tag "b02ad8c07885cfe0e83ec04d249570831cf3e070"}
                 {:repo "https://github.com/joy-framework/halo" :tag "70e03184d303f89489269bb440568727aceee9b1"}]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")

(declare-binscript
  :main "joy")

(declare-source
  :source @["src/joy" "src/joy.janet"])
