# Routing

Routing in joy is done with a macro of arrays, each route is an array and the third item in that array is a function that takes one argument, the [request map](requests-and-responses.md).

Take a look at these routes:

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

This is a pretty typical first step in any web app, you have a home page, and then you have 7 routes that represent forms and actions you can take on a database table. Joy does not differ from this basic formula, because it works. If it ain't broke, right?

You can reference these routes in 3 different ways:

1. `redirect-to`
2. `form-for`
3. `url-for`

Let's take a look at redirect-to:

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