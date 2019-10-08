# sql.janet
(import ../helper :as helper)


(defn where-op [[k v]]
  (cond
    (= v 'null) "is null"
    :else (string "= :" k)))


(defn where-clause [params]
  (when (dictionary? params)
    (->> (pairs params)
         (map |(string (first $) " " (where-op $)))
         (helper/join-string " and "))))


(defn from [table-name params]
  (string "select * from " (helper/snake-case table-name) " where " (where-clause params)))


(defn fetch-options [args]
  (when (not (empty? args))
    (let [{:order order :limit limit :offset offset} (apply table args)
          order-by (when (not (nil? order)) (string "order by " order))
          limit (when (not (nil? limit)) (string "limit " limit))
          offset (when (not (nil? offset)) (string "offset " offset))]
      (->> [order-by limit offset]
           (filter |(not (nil? $)))
           (helper/join-string " ")))))


(defn clone-inside [an-array]
  (if (> (length an-array) 2)
    (let [first-val (first an-array)
          last-val (last an-array)
          inner (filter |(and (not= $ first-val)
                           (not= $ last-val))
                  an-array)
          cloned-inner (interleave inner inner)]
      (mapcat identity [first-val cloned-inner last-val]))
    an-array))


(defn join [[left right]]
  (string "join " left " on " left ".id = " right "." left "_id"))


(defn fetch-joins [keywords]
  (when (> (length keywords) 1)
    (->> (clone-inside keywords)
         (partition 2)
         (map join)
         (reverse)
         (helper/join-string " "))))


(defn fetch [path & args]
  (let [keywords (filter keyword? path)
        ids (filter |(not (keyword? $)) path)
        where (when (not (empty? ids))
                (string "where "
                  (->> (partition 2 path)
                       (filter |(= 2 (length $)))
                       (mapcat |(array (string (first $) ".id") (last $)))
                       (apply table)
                       (where-clause))))]
    (->> ["select * from"
          (last keywords)
          (fetch-joins keywords)
          where
          (fetch-options args)]
         (filter |(not (nil? $)))
         (helper/join-string " "))))


(defn insert [table-name params]
  (let [columns (->> (keys params)
                     (map string)
                     (helper/join-string ", "))
        vals (->> (keys params)
                  (map |(string ":" $))
                  (helper/join-string ", "))]
    (string "insert into " (helper/snake-case table-name) " (" columns ") values (" vals ")")))


(defn update [table-name params]
  (let [columns (->> (keys params)
                     (map string)
                     (helper/join-string ", "))
        vals (->> (keys params)
                  (map |(string ":" $))
                  (helper/join-string ", "))]
    (string "insert into " (helper/snake-case table-name) " (" columns ") values (" vals ")")))
