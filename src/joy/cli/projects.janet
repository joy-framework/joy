(import ../helper :prefix "")
(import path)
(import cipher)
(import musty)


(defn generate [project-name]
  (let [sys-path (dyn :syspath)
        template-path (path/join sys-path "joy" "template")
        main-path (path/join project-name "main.janet")
        project-path (path/join project-name "project.janet")
        env-path (path/join project-name ".env")]

    (os/shell
      (string/format "cp -r %s %s" template-path project-name))

    (spit main-path (musty/render (slurp main-path) {:project-name project-name}))
    (spit project-path (musty/render (slurp project-path) {:project-name project-name}))
    (spit env-path (musty/render (slurp env-path) {:encryption-key (cipher/encryption-key)}))))
