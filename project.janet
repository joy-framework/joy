(declare-project
  :name "joy"
  :description "A full stack janet web framework"
  :dependencies ["https://github.com/janet-lang/json"
                 {:repo "https://github.com/janet-lang/sqlite3" :tag "a3a254003c605cf4e048963feda70a60537057d9"}
                 {:repo "https://github.com/janet-lang/path" :tag "d8619960d428c45ebb784600771a7c584ae49431"}
                 {:repo "https://github.com/joy-framework/cipher" :tag "0.2.0"}
                 {:repo "https://github.com/joy-framework/codec" :tag "f50c00462b9d048034ee8bdd2f6af6e67bc5aff4"}
                 {:repo "https://github.com/joy-framework/halo" :tag "a276646d269fc8a8df5336015579219300378ac2"}
                 {:repo "https://github.com/andrewchambers/janet-uri" :tag "921c16d008444792ad262f7aaff87549acfc4240"}
                 {:repo "https://git.sr.ht/~bakpakin/temple" :tag "ed7e83e8779e2a54e23bbbcc75366ade2dd5372a"}
                 {:repo "https://github.com/joy-framework/tester"}]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")

(declare-binscript
  :main "joy")

(declare-source
  :source @["src/joy" "src/joy.janet"])
