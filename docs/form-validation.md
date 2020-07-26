# Form Validation

Form validation is something that happens on almost any handler that isn't a GET, so it's something joy has built in and hopefully makes it more convenient than calling predicates on `(request :body)`.

## No validation

```clojure
(use joy)

(def sql `create table if not exists todos (id integer primary key, name text not null)`)

(db/execute sql)

(route :get "/todos/new" :todos/new)
(route :post "/todos" :todos/create)

(defn todos/new [req]
  (def body (req :body))

  (form-for [req :todos/create]
    [:input {:type "text" :name "name" :value (body :name)}]

    [:button {:type "submit"}
      "Save"]))


(defn todos/create [req]
  (def body (req :body))

  (db/insert :todos body)

  (redirect-to :todos/index))
```

This works great, until someone leaves the input blank and then joy throws an error that the column can't be null. You could just do this:

```clojure
(defn todos/create [req]
  (def body (req :body))

  (when (body :name)
    (db/insert :todos body))

  (redirect-to :todos/index))
```

Not bad! Of course you're going to have to string together quite a few of those whens or put an and in there or something when you have more inputs in a form than just one. Also, what if someone malicious decides to send more than just what's in the form? Then you're going to get "column does not exist" errors. So you'll have to do something like this:

```clojure
(defn todos/create [req]
  (def body (req :body))

  (when (body :name)
    (db/insert :todos {:name (body :name)}))

  (redirect-to :todos/index))
```

Not bad, but it's annoying when you have to repeat `(body :...)` for as many inputs as there are in the field. Also, this code doesn't handle the case where there are errors and you have to re-render the form. Luckily, joy has a solution.

## Validation

Here's what validation/permitting parameters looks like:

```clojure
(def params
  (params :todos
    (validates [:name] :required true)
    (permit [:name])))
```

It's compact, can "scale" to quite a few parameters and shows up by default when you use `joy create route ...`

There are a few things going on here:

1. Creates a new dictionary with only the keys specified in the tuple passed to `permit`
2. Calls `(not (blank? x))` on every key specified in `validates`

There are a few more options you can pass to the `validates` function:

- `:required` - fails if the body param is either blank or missing
- `:message` - the message attached to the param
- `:min-length` - fails if the body param has less characters
- `:max-length` - fails if the body param has more characters
- `:email` - fails if the body param doesn't have an `@` symbol in the string
- `:matches` - takes a PEG and matches the value in the body parameter to that PEG, fails if it doesn't
- `:uri` - fails if the body param isn't a uri

Here's how you can use it in your handlers:

```clojure
(defn todos/new [req]
  (def {:body body :errors errors} req)

  (form-for [req :todos/create]
    [:label {:for "name"} "name"]
    [:input {:type "text" :name "name" :value (body :name)}]
    [:div (errors :name)]

    [:button {:type "submit"}
      "Save"]))


(defn todos/create [req]
  (def result (->> (params req)
                   (db/insert)
                   (rescue)))

  (def [errors todo] result)

  (if errors
    (todos/new (put req :errors errors))
    (redirect-to :todos/index)))
```

This code is almost as short as the no validation code BUT it

1. Validates the presence of the `:name` key
2. Takes out only the keys specified by name in `permit`
3. Handles errors
4. Re-renders the form with the `:errors` key

Hopefully that helps with form validation and locking down what data is allowed to pass into your handlers.
