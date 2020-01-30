# HTML Rendering

HTML rendering is a little different in joy vs traditional web frameworks. Check it out

## No Templates

HTML is represented by a large nested array, sounds horrible right? Stay with me, it'll be ok in the end

```clojure
(import joy)

(joy/html
  [:div {:class "row"}
    [:div {:class "col-xs-12"}
      [:p "Joy to the web"]]])
```

This outputs

```html
<div class="row">
  <div class="col-xs-12">
    <p>Hello world</p>
  </div>
</div>
```

See, it wasn't that bad, it's actually kind of readable

That's pretty much all there is to it, but we can go further

## Dynamic data

How do you do loops?!

```clojure
(defn item [{:name name}]
  [:li {:class "list-item"} name])

(let [items [{:name "name1"} {:name "name2"}]]
  [:ul {:class "list"}
    (map item items)])
```

Other dynamic data that isn't loops, works similarly. You have the full power of the janet language at your disposal! There's no separate template syntax to learn!

## Unescaped HTML strings

Another benefit of having the language represent html is everything gets escaped by default. The only problem is when you *dont* want everything escaped, like inserting a string of markdown for example. There's a way around it: `raw`

```clojure
(import joy :prefix "")
(import moondown)

(defn show [request]
  (let [title (get-in request [:params :title])]
    (with-file [f (string/format "posts/%s.md" title)]
      (render :html
        [:div {:class "white bg-transparent lh-copy mt4"}
          (raw (moondown/render (string (file/read f :all))))]))))
```

## Layouts

How do you get things like re-use and layouts? Functions!

```clojure
(import joy)

(defn home [request])
  [:div "home"]

(joy/defroutes web
  [:get "/" home])

(defn layout [response])
  (let [{:body body} response]
    (joy/respond :html
      (joy/html
       (joy/doctype :html5)
       [:html {:lang "en"}
        [:head
         [:meta {:charset "utf-8"}]
         [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
         [:link {:href "/app.css" :rel "stylesheet"}]
         [:title "title"]]
        [:body
         body
         [:script {:src "/app.js"}]]]))))


(def app (-> (joy/handler routes)
             (joy/layout layout)))
```

Now when you call `(app {:uri "/" :method :get})` it will return an html string in the response body

```html
<!DOCTYPE HTML>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href="/app.css" rel="stylesheet" />
    <title>title</title>
  </head>
  <body>
    <div>home</div>
    <script src="/app.js"></script>
  </body>
</html>
```

There's more about how to show different layouts based on different routes in the [authentication section](authentication.md)
