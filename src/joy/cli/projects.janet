(import ../helper :as helper)
(import path)
(import cipher)
(import codec)

(defn generate [project-name]
  (let [sys-path (dyn :syspath)
        template-path (path/join sys-path "joy" "template")]
    (var tmp "")
    (os/shell
      (string/format "cp -r %s %s" template-path project-name))

    (helper/with-file [f (path/join project-name "src" "layout.janet") :r]
      (set tmp (->> (file/read f :all)
                    (string/replace-all "%project-name%" project-name))))
    (helper/with-file [f (path/join project-name "src" "layout.janet") :w]
      (file/write f tmp))

    (helper/with-file [f (path/join project-name "project.janet") :r]
      (set tmp (->> (file/read f :all)
                    (string/replace-all "%project-name%" project-name))))
    (helper/with-file [f (path/join project-name "project.janet") :w]
      (file/write f tmp))

    (helper/with-file [f (path/join project-name ".env") :r]
      (set tmp (->> (file/read f :all)
                    (string/replace-all "%encryption-key%" (cipher/encryption-key)))))
    (helper/with-file [f (path/join project-name ".env") :w]
      (file/write f tmp))))
