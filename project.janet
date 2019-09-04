(declare-project
  :name "joy"
  :description "A full stack janet web framework"
  :dependencies [{:repo "https://github.com/janet-lang/json" :tag "fc59d46f06501569c21d18fff3df15e1494bf144"}
                 {:repo "https://github.com/joy-framework/tester" :tag "c14aff3591cb0aed74cba9b54d853cf0bf539ecb"}
                 {:repo "https://github.com/janet-lang/sqlite3" :tag "5e0ad6749a95a08818369d8467c346889496503d"}]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")


(declare-native
  :name "circlet"
  :source @["lib/circlet/circlet.c" "lib/circlet/mongoose.c"])

(declare-source
  :source @["src/joy.janet"])

(phony "update-mongoose" []
      (shell "curl https://raw.githubusercontent.com/cesanta/mongoose/master/mongoose.c > lib/circlet/mongoose.c")
      (shell "curl https://raw.githubusercontent.com/cesanta/mongoose/master/mongoose.h > lib/circlet/mongoose.h"))
