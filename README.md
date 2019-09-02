## You've found joy!

Joy will be a full stack web framework written in [janet](https://github.com/janet-lang/janet)

**This project is in early development so expect major changes**

```clojure
(ns app
  (:require [joy]))

(defn home [request]
  (joy/respond :text
    "Have some joy with janet 😇"))

(def routes [[:get "/" home]])

(def app (joy/app routes))

(joy/server app {:port 3000})
```
