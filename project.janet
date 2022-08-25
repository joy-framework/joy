(declare-project
  :name "joy"
  :description "A full stack web framework written in janet"
  :dependencies [{:repo "https://github.com/andrewchambers/janet-uri" :tag "9737a6aee88cc2e426b496532014d6d85605afc2"}
                 {:repo "https://github.com/janet-lang/spork" :tag "f547fee9ebfe96c09029bfe232336aab1212a617"}
                 {:repo "https://github.com/pyrmont/musty" :tag "e1a821940072a5ae5ddc9d3cb2ae6d1bdba41468"}
                 "https://github.com/joy-framework/cipher"
                 "https://github.com/joy-framework/halo2"
                 "https://github.com/joy-framework/tester"
                 "https://github.com/joy-framework/db"
                 "https://github.com/swlkr/janet-html"
                 "https://github.com/janet-lang/sqlite3"]
  :author "Sean Walker"
  :license "MIT"
  :url "https://github.com/joy-framework/joy"
  :repo "git+https://github.com/joy-framework/joy")

(declare-binscript
  :main "joy")

(declare-source
  :source @["src/joy" "src/joy.janet"])
