(import ./html :as html)


(defn- concat-files [filenames ext]
  (var parts @[])
  (loop [filename :in filenames]
    (let [f (file/open (string "public/" filename) :r)
          str (file/read f :all)
          parts (array/push parts str)]
      (file/close f))
   (let [f (file/open (string "public/bundle." ext) :w)]
     (file/write f (string/join parts "\n\n"))
     (file/close f))))


(def- css? (partial string/has-suffix? ".css"))
(def- js? (partial string/has-suffix? ".js"))
(def- bundle? (partial string/has-prefix? "bundle"))


(defn bundle [[path]]
  (let [files (sort (os/dir (or path "public")))
        files (filter |(not (bundle? $)) files)
        css-files (filter css? files)
        js-files (filter js? files)]
    (concat-files css-files "css")
    (concat-files js-files "js")))
