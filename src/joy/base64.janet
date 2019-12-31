(import codec)

(defn encode [str]
  (-> (codec/encode str) (string/trimr "\0")))

(defn decode [str]
  (codec/decode str))
