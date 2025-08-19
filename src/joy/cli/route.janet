(import ../helper :prefix "")
(import ../env :as env)
(import db)
(import spork/path)
(import musty)


(defn template []
  (slurp (path/join (dyn :syspath) "joy" "cli" "route.txt")))


(defn render [page]
  (musty/render (template) {:page page}))


(defn use-line [page]
  (string/format "(use ./routes/pages)" page))


(defn used? [page lines]
  (find |(= (use-line page) $) lines))


(defn new-main [page]
  (def s (slurp "main.janet"))

  (def lines (string/split "\n" s))

  (unless (used? page lines)
    (string/join (array/insert lines 1 (use-line page))
                 "\n")))


(defn new-pages [page]
  (def filename (path/join "routes" "pages.janet"))

  (def s (if (os/stat filename)
           (slurp filename)
           "(use joy)\n"))

  (def lines (string/split "\n" s))

  (def route (render page))

  (string/join (array/push lines route)
               "\n"))


(defn create [page]
  (os/mkdir "routes")

  (def new-pages (new-pages page))
  (def new-main (new-main page))

  (with-file [f (path/join "routes" "pages.janet") :w]
    (file/write f new-pages))

  (when new-main
    (with-file [f1 "main.janet" :w]
      (file/write f1 new-main))))
