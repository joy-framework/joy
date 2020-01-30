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
    (respond :html
      (html
       (doctype :html5)
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
