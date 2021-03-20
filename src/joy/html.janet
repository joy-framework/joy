# html.janet
# parts of the code shamelessly stolen from https://github.com/brandonchartier/janet-html
(import ./env :as env)
(import janet-html :prefix "" :export true)


(defn find-bundle [ext]
  (let [bundle (as-> (os/dir "public") ?
                     (filter |(string/has-prefix? "bundle" $) ?)
                     (filter |(string/has-suffix? ext $) ?)
                     (get ? 0))]
    (if (and env/production?
             (nil? bundle))
      (printf "Warning: JOY_ENV is set to production but there was no bundled %s file. Run joy bundle to fix this." ext)
      bundle)))


(defn script [dict]
  (def bundle (find-bundle ".js"))
  (def src (if (indexed? (dict :src))
             (dict :src)
             [(dict :src)]))

  (if (nil? bundle)
    (map |(tuple :script (merge dict {:src $})) src)
    [:script (merge dict {:src (string "/" bundle)})]))


(defn link [dict]
  (def bundle (find-bundle ".css"))
  (def href (if (indexed? (dict :href))
              (dict :href)
              [(dict :href)]))

  (if (nil? bundle)
    (map |(tuple :link (merge dict {:href $ :rel "stylesheet"})) href)
    [:link (merge dict {:href (string "/" bundle) :rel "stylesheet"})]))
