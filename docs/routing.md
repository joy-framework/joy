# Routing

Routing in joy can happen three different ways each with it's own trade offs:

1. `routes`/`defroutes` (traditional web framework routing)
2. `route` ("decorator" routing)
3. `auto-routes` (magical, oftentimes confusing routing that demos great)

I'll go over each one below:

### Traditional routing

This is `routes`/`defroutes`

```clojure
(defroutes app
  [:get "/" home]
  [:get "/accounts" accounts/index]
  [:get "/accounts/new" accounts/new]
  [:get "/accounts/:id/edit" accounts/edit]
  [:get "/accounts/:id" accounts/show]
  [:post "/accounts" accounts/create]
  [:patch "/accounts/:id" accounts/patch]
  [:delete "/accounts/:id" accounts/destroy])
```

or if you don't like not being able to find `defroutes` with ctags:

```clojure
(def app (routes [:get "/" home]
                 [:get "/accounts" accounts/index]
                 [:get "/accounts/new" accounts/new]
                 [:get "/accounts/:id/edit" accounts/edit]
                 [:get "/accounts/:id" accounts/show]
                 [:post "/accounts" accounts/create]
                 [:patch "/accounts/:id" accounts/patch]
                 [:delete "/accounts/:id" accounts/destroy])
```

There really is no trade off here except that you have to define functions and then define the routes separately, typically in another file or another place in the same file. Not the best for moving quickly, if you have a small app.

### Decorator Routing

This is similar to some of the stuff you see in typescript or something where you "decorate" a method in a class. In this case there are no classes so decorating means just calling a function and saving everything in a `dyn`. Same effect since routes typically are not changing after app startup.

```clojure
(route :get "/" :home)
(defn home [request])

(route :get "/accounts" :accounts/index)
(defn accounts/index [request])

(route :get "/accounts/new" :accounts/new)
(defn accounts/new [request])

etc...
```

This works pretty well if you want to move quickly and not jump around to different files to define routes. This is what I typically use, but feel free to choose the best method that suits your style. The trade off here is that resolving functions from keywords doesn't appear to work if you use `main.janet` and try to declare an executable, which I haven't really ever done. PRs welcome on that front though.

### Auto routing / Function routing

This is something near and dear to my heart since it cuts out even defining the route in the first place.

```clojure
(defn / [request])

(defn /accounts [request])

(defn /accounts/new [request])

(defn /accounts/post [request])

(defn /accounts/:id/patch [request])

(defn /accounts/:id/delete [request])
```

So this looks suspect, it almost looks too magical and in some respects it is. Defining `/` overrides the core divide function 😬 so you know, try redefining it to `div` or something or just don't use auto routes since they are very magical. Also, as you can see verbs are supported as long as they are the last part of the route. I probably wasn't in my right mind when I wrote this feature, but there it is. If you're a madman like me, feel free to move *very* quickly at the expense of going insane.

One last thing I wanted to talk about that doesn't fit into the above is wildcard routing:

### Wildcard routes

```clojure
(defn everything [request]
  (let [parts (get request :wildcard)]
    @{:status 200 :body (text/plain (string/join parts " "))}))

(def routes (routes [:get "/static1/*/static2/*/static3" everything]
                    [:get "/*" everything]))

(def app (app {:routes routes}))

(app {:method "GET" :uri "/hello"}) ; => "hello"
(app {:method "GET" :uri "/heres/a/long/example"}) ; => "heres a long example"
(app {:method "GET" :uri "/"}) ; => ""
(app {:method "GET" :uri "/static1/dynamic1/static2/dynamic2/static3"}) ; => "dynamic1 dynamic2"
(app {:method "GET" :uri "/static1/dyn1/static2/dyn2/static3"}) ; => "dyn1 dyn2"
```

If you used either `route`, `routes` or `defroutes` You can reference these routes in five different ways:

1. `redirect-to`
2. `form-for`
3. `action-for`
4. `form-with`
5. `url-for`

### redirect-to

`redirect-to` does just what it sounds like, it takes a route name, in this case, the function name like `accounts/index` and you make that a keyword by prepending a colon `:accounts/index` and it returns a redirect [response dictionary](requests-and-responses.md).

```clojure
(redirect-to :accounts/index)
```

Will return

```clojure
{:status 200 :body " " :headers {"Location" "/accounts"}}
```

Pretty nifty! Here's a more complete example with route params

```clojure
(redirect-to :accounts/show {:id 1})
```

will return

```clojure
{:status 200 :body " " :headers {"Location" "/accounts/1"}}
```

### form-for

`form-for` is a little more complex, it takes an array of `request` and a route name and any route parameters and builds a form with an anti csrf-token

```clojure
(let [account {:name "name value"}]
  (form-for [request :accounts/patch {:id 1}]
    (label :name "Name")
    (text-field account :name)

    (submit "Save")))
```

this would output

```html
<form action="accounts/1" method="post">
  <label for="name">Name</label>
  <input type="text" name="name" value="name value" />
  <input type="hidde" name="_method" value="patch" />
  <input type="hidden" name="csrf-token" value="random anti-csrf string" />
  <input type="submit" value="Save" />
</form>
```

### form-with

`form-with` is similar to `form-for` but gives you more control to add arbitrary attributes to your form

```clojure
(let [account {:name "name value"}]
  (form-with request {:method "patch" :action "/accounts/1"}
    (label :name "Name")
    (text-field account :name)

    (submit "Save")))
```

this would output

```html
<form action="accounts/1" method="post">
  <label for="name">Name</label>
  <input type="text" name="name" value="name value" />
  <input type="hidde" name="_method" value="patch" />
  <input type="hidden" name="csrf-token" value="random anti-csrf string" />
  <input type="submit" value="Save" />
</form>
```

similar to `form-for` but now you can add this like `:enctype`, `:class` or `:id`

### action-for

This has been in here forever but I don't think it's been documented, this is similar to `url-for` but it returns a dictionary that `form-with` can use:

```clojure
(defroutes routes
  [:get "/" home]
  [:get "/accounts" accounts/index]
  [:get "/accounts/new" accounts/new]
  [:get "/accounts/:id/edit" accounts/edit]
  [:get "/accounts/:id" accounts/show]
  [:post "/accounts" accounts/create]
  [:patch "/accounts/:id" accounts/patch]
  [:delete "/accounts/:id" accounts/destroy])

(action-for :accounts/create) ; => {:method "post" :action "/accounts"}
(action-for :accounts/patch {:id 1}) ; => {:method "post" :_method "patch" :action "/accounts/1"}
(action-for :accounts/destroy {:id 1}) ; => {:method "post" :_method "delete" :action "/accounts/1"}

(form-with request (action-for :accounts/create))
(form-with request (action-for :accounts/patch {:id 1}))
```

A little simpler and more control over attributes, but more verbose.

### url-for

`url-for` is similar to `redirect-to` but instead of returning a response, it returns a string representing the route

```clojure
(defroutes app
  [:get "/accounts/:id/edit" accounts/edit])

(url-for :accounts/edit {:id 1})
```

would return

```clojure
"accounts/1/edit"
```
