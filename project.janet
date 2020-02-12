(declare-project
  :name "joy"
  :description "A full stack janet web framework"
  :dependencies [{:repo "https://github.com/janet-lang/json" :tag "fc59d46f06501569c21d18fff3df15e1494bf144"}
                 {:repo "https://github.com/janet-lang/sqlite3" :tag "a3a254003c605cf4e048963feda70a60537057d9"}
                 {:repo "https://github.com/janet-lang/path" :tag "d8619960d428c45ebb784600771a7c584ae49431"}
                 {:repo "https://github.com/joy-framework/cipher" :tag "87fc9bc38b335d0f31c93d6c95f35b8a6abce6af"}
                 {:repo "https://github.com/joy-framework/codec" :tag "f50c00462b9d048034ee8bdd2f6af6e67bc5aff4"}
                 {:repo "https://github.com/joy-framework/halo" :tag "fd34201fee41b372314aede9e72044d711510afa"}
                 {:repo "https://github.com/andrewchambers/janet-uri" :tag "d191ed238dc7c4966f121f9f4c40b19cc75e34ee"}
                 {:repo "https://git.sr.ht/~bakpakin/temple" :tag "ed7e83e8779e2a54e23bbbcc75366ade2dd5372a"}
                 {:repo "https://github.com/joy-framework/tester" :tag "0.2.1"}]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")

(declare-binscript
  :main "joy")

(declare-source
  :source @["src/joy" "src/joy.janet"])
