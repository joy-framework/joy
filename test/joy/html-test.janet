(import tester :prefix "" :exit true)
(import "src/joy/html" :as html)


(deftest
  (test "html/attributes with a dictionary"
    (= ` id="id" class="class"` (html/attributes {:class "class" :id "id"})))

  (test "html/attributes without a dictionary"
    (= "" (html/attributes nil)))

  (test "empty div"
    (= "<div></div>" (html/render [:div])))

  (test "empty div with attributes"
    (= `<div class="class"></div>` (html/render [:div {:class "class"}])))

  (test "non-empty div without attributes"
    (= `<div>hello world</div>` (html/render [:div "hello world"])))

  (test "non-empty div with attributes"
    (= `<div class="class">hello world</div>` (html/render [:div {:class "class"} "hello world"])))

  (test "html/render with an empty child node"
    (= `<div class="class"><span></span></div>` (html/render [:div {:class "class"}
                                                              [:span]])))

  (test "html/render with a nested node without attributes and content"
    (= `<div class="class"><span>span</span></div>` (html/render [:div {:class "class"}
                                                                  [:span "span"]])))

  (test "html/render with a nested node with attributes and content"
    (= `<div class="class"><span id="id">span</span></div>` (html/render [:div {:class "class"}
                                                                          [:span {:id "id"} "span"]])))

  (test "html/render with an escaped nested node with attributes and content"
    (= `<div class="class"><span id="id">&lt;span&gt;</span></div>`
       (html/render [:div {:class "class"}
                      [:span {:id "id"} "<span>"]]))))
