# Requests and Responses

Everything in joy revolves around request and response maps.

## Requests

Requests in joy look like this:

```clojure
{:uri "/"
 :method "GET"
 :headers {"Accept" "text/html"}}
```

Keep that structure in your mind because it gets passed to every route and every handler and every middleware function and every form helper, it's everywhere. It ties the whole thing together and makes everything work.

Here's what I mean.

Take a look at this route:

```clojure
(defroutes app
  [:get "/" home])
```

Now take a look at this handler

```clojure
(defn home [request]
  {:status 200 :body "home" :headers {"Content-Type" "text/plain"}})
```

That `request` argument to that function has the structure from before:

```clojure
(defn home [{:uri uri :method method :headers headers}]
  {:status 200 :body "home" :headers {"Content-Type" "text/plain"}})
```

### Responses

If you were so inclined to destructure it, that's what it looks like. Now take a closer look at that response, they always have this structure:

```clojure
{:status 200
 :body "body"
 :headers {"Content-Type" "application/json"}}
```

That's pretty much all there is to joy, it's dictionaries in and dictionaries out for the most part. The thing that makes the framework a framework is the [middleware](middleware.md) and to some extent the various helpers that help with [routing](routing.md) and [form submission](form-submission.md).
