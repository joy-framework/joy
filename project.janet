(declare-project
  :name "joy"
  :description "A full stack janet web framework"
  :dependencies [{:repo "https://github.com/janet-lang/json" :tag "fc59d46f06501569c21d18fff3df15e1494bf144"}
                 {:repo "https://github.com/joy-framework/tester" :tag "c14aff3591cb0aed74cba9b54d853cf0bf539ecb"}
                 {:repo "https://github.com/janet-lang/sqlite3" :tag "5e0ad6749a95a08818369d8467c346889496503d"}
                 {:repo "https://github.com/joy-framework/uuid" :tag "b9154db174b55cdaec8b562e64d254ada86d5710"}
                 {:repo "https://github.com/joy-framework/cipher" :tag "a9432889da39cba58c1bb2625f32d3acac3948c7"}
                 {:repo "https://github.com/joy-framework/codec" :tag "b02ad8c07885cfe0e83ec04d249570831cf3e070"}
                 {:repo "https://github.com/joy-framework/halo" :tag "99b2df9583646e86ea5a79316aeccf7c64925cbf"}]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")

(declare-binscript
  :main "joy")

(declare-source
  :source @["src/joy" "src/joy.janet"])
