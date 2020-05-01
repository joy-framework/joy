(import tester :prefix "" :exit true)
(import "src/joy/html" :as html)


(deftest
  (test "empty div"
    (= "<div></div>" (html/html [:div])))

  (test "empty div with spaces"
    (= "<div>hello world</div>" (html/html [:div "hello world"])))

  (test "empty div with special characters"
    (= "<div>!@#$%^&amp;*()[]-_+=~`|\\:;&quot;&#x27;</div>" (html/html [:div "!@#$%^&*()[]-_+=~`|\\:;\"'"])))

  (test "empty div with attributes"
    (= `<div class="class"></div>` (html/html [:div {:class "class"}])))

  (test "special characters again"
    (= "<div>&lt;script&gt;alert(&#x27;hello xss!&#x27;)&lt;&#x2F;script&gt;</div>" (html/html [:div "<script>alert('hello xss!')</script>"])))

  (test "special characters some more"
    (= "<input type=\"password\" value=\"%\" />" (html/html [:input {:type "password" :value "%"}])))

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

  # (test "a link inside of some content"
  #   (= `<div class="class">View the <a href="https://github.com/joy-framework/joy">joy</a> source</div>`
  #      (print (html/html [:div {:class "class"}
  #                          "View the "
  #                          [:a {:href "https://github.com/joy-framework/joy"} "joy"]
  #                          " source"]))))

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
          [:h1 "h1"]]]))))
