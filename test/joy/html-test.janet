(import tester :prefix "" :exit true)
(import ../../src/joy/html :as html)


(deftest
  (test "element with class shorthand"
    (is (= "<div class=\"bg-dark pa-m\"></div>"
           (html/html [:div.bg-dark.pa-m]))))

  (test "element with class shorthand and class attribute working together in harmony"
    (is (= "<div class=\"bg-dark pa-m class\"></div>"
           (html/html [:div.bg-dark.pa-m {:class "class"}]))))

  (test "element with classes array working"
    (is (= "<div class=\"bg-dark pa-m\"></div>"
           (html/html [:div {:class '[bg-dark pa-m]}]))))

  (test "empty div"
    (is (= "<div></div>" (html/html [:div]))))

  (test "empty div with spaces"
    (= "<div>hello world</div>" (html/html [:div "hello world"])))

  (test "empty div with special characters"
    (= "<div>!@#$&#37;^&amp;*()[]-_+=~`|\\:;&quot;&#x27;</div>" (html/html [:div "!@#$%^&*()[]-_+=~`|\\:;\"'"])))

  (test "empty div with attributes"
    (= `<div class="class"></div>` (html/html [:div {:class "class"}])))

  (test "special characters again"
    (= "<div>&lt;script&gt;alert(&#x27;hello xss!&#x27;)&lt;&#x2F;script&gt;</div>" (html/html [:div "<script>alert('hello xss!')</script>"])))

  (test "non-empty div without attributes"
    (= `<div>hello world</div>` (html/html [:div "hello world"])))

  (test "one nested element no attributes"
    (= `<div><span>hello world</span></div>` (html/html [:div [:span "hello world"]])))

  (test "two nested elements no attributes"
    (= `<div><span>hello world</span><span>2</span></div>`
       (html/html [:div
                   [[:span "hello world"]
                    [:span "2"]]])))

  (test "non-empty div with attributes"
    (= `<div class="class">hello world</div>` (html/html [:div {:class "class"} "hello world"])))

  (test "html/html with an empty child node"
    (= `<div class="class"><span></span></div>` (html/html [:div {:class "class"}
                                                            [:span]])))

  (test "html/html with a nested node without attributes and content"
    (= `<div class="class"><span>span</span></div>` (html/html [:div {:class "class"}
                                                                [:span "span"]])))

  (test "a link inside of some content"
    (= `<div class="class">View the <a href="https://github.com/joy-framework/joy">joy</a> source</div>`
       (html/html [:div {:class "class"}
                    "View the "
                    [:a {:href "https://github.com/joy-framework/joy"} "joy"]
                    " source"])))

  (test "html/html with a nested node with attributes and content"
    (= `<div class="class"><span id="id">span</span></div>` (html/html [:div {:class "class"}
                                                                        [:span {:id "id"} "span"]])))

  (test "html/html with an escaped nested node with attributes and content"
    (= `<div class="class"><span id="id">&lt;span&gt;</span></div>`
       (html/html [:div {:class "class"}
                    [:span {:id "id"} "<span>"]])))

  (test "html/html with a raw node"
    (= "<div><br /></div>"
       (html/html [:div (html/raw "<br />")])))

  (test "html/html with img element"
    (= `<img src="joy.jpg" />`
       (html/html [:img {:src "joy.jpg"}])))

  (test "html/html with realistic input"
    (= `<html lang="en"><head><title>title</title></head><body><h1>h1</h1></body></html>`
       (html/html
        [:html {:lang "en"}
         [:head
          [:title "title"]]
         [:body
          [:h1 "h1"]]])))

  (test "html/html with doctype"
    (= `<!DOCTYPE HTML><html lang="en"><head><title>title</title></head><body><h1>h1</h1></body></html>`
       (html/html
        (html/doctype :html5)
        [:html {:lang "en"}
         [:head
          [:title "title"]]
         [:body
          [:h1 "h1"]]])))

  (test "html/html with doctype and no attributes in :html"
    (= `<!DOCTYPE HTML><html><head><title>title</title></head><body><h1>h1</h1></body></html>`
       (html/html
        (html/doctype :html5)
        [:html
         [:head
          [:title "title"]]
         [:body
          [:h1 "h1"]]])))

  (test "html with when"
    (= `<!DOCTYPE HTML><html><head><title>title</title></head><body><h1>h1</h1></body></html>`
       (html/html
        (html/doctype :html5)
        [:html
         [:head
          [:title "title"]]
         [:body
          (when false
            [:div "hello"])
          [:h1 "h1"]]])))

  (test "html with multiple strings"
    (= "<div>helloworld</div>"
       (html/html [:div "hello" "world"])))

  (test "html with attrs and multiple strings"
    (= "<div id=\"1\">helloworld</div>"
       (html/html [:div {:id 1} "hello" "world"])))

  (test "html with multiple indices"
    (= "<div><p></p><br /></div>"
       (html/html [:div [:p] [:br]]))))
