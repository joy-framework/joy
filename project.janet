(declare-project
  :name "joy"
  :description "A full stack web framework written in janet"
  :dependencies [{:repo "https://github.com/andrewchambers/janet-uri" :tag "9737a6aee88cc2e426b496532014d6d85605afc2"}
                 {:repo "https://github.com/janet-lang/json" :tag "61437d96b5df6eb7e524f88847e7d7521201662d"}
                 {:repo "https://github.com/janet-lang/path" :tag "0ae7b60b8aaaa7f80f84692b7efb8e46b7d38eb3"}
                 {:repo "https://github.com/janet-lang/sqlite3" :tag "308dfaa84b0c08c79f0bf7a6bc7adf97dc1e201a"}
                 {:repo "https://github.com/pyrmont/musty" :tag "e1a821940072a5ae5ddc9d3cb2ae6d1bdba41468"}
                 "https://github.com/joy-framework/cipher"
                 "https://github.com/joy-framework/codec"
                 "https://github.com/joy-framework/halo"
                 "https://github.com/joy-framework/bundler"
                 "https://github.com/joy-framework/db"
                 "https://github.com/joy-framework/dotenv"
                 "https://github.com/joy-framework/tester"]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")

(declare-binscript
  :main "joy")

(declare-source
  :source @["src/"])
