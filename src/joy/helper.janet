(defn kebab-case [val]
  (string/replace-all "_" "-" val))

(defn snake-case [val]
  (string/replace-all "-" "_" val))
