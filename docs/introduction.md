# Introduction

Like most web frameworks, joy consists of four things:

1. Functions
2. Routes
3. Middleware
4. Handlers (a combo of routes, middleware and functions, also known as controller methods or actions)

Unlike most web frameworks, these four things are not opaque and entirely up to you on how you structure them

## Functions

```clojure
(use joy)

(defn hello [request]
  (def params (request :params))

  (text/plain (string "hello " (params :name))))
```

This is a just a janet function, it takes a request dictionary and returns a response dictionary, the `text/plain` function is just sugar for `{:status 200 :body "hello!" :headers {"Content-Type" "text/plain"}}` which is the janet dictionary literal.

## Routes

```clojure
(defroutes hello-routes
  [:get "/" home]
  [:post "/" sweet-home]
  [:get "/hello/:name" hello])
```

Those are routes, they take any number of tuples in the form of

`[:http-verb "/route/string" name-of-function :optional-alias-of-function]`

## Middleware

Next we have middleware, joy has several middleware for working with web applications, but you can make your own and swap or drop all of the built in middleware if you want.

```clojure
(def hello-handler (-> (handler hello-routes)
                       (logger)))
```

Here's an example using the built in logger, the `handler` function takes an array of routes and returns a handler wrapped in the middleware functions that call it.

Here's how a logger middleware function could look

```clojure
(defn logger [handler]
  (fn [request]
    (printf "%q" request)
    (let [response (handler request)]
      (printf "%q" response)
      response)))
```

A middleware function takes a handler (which is a function that takes routes and returns a function that takes a request), and then calls that handler on the request in the function it returns!

It's turtles all the way down.

## Server & Handlers

The last part of this is wiring up the middleware and handlers with the actual http server, which works like this:

```clojure
(server hello-handler 8000)
```

Which starts up the loop and listens on port 8000 for incoming http requests on `http://localhost:8000`

In the case of multiple handlers, you can combine them before calling `server` with this handy function

```clojure
(def app (handlers hello-handler some-other-handler a-third-handler))
```

This calls the handlers from left to right, when a route doesn't match a given set of routes for that handler, it returns nil
and the next handler (function + middleware) is called.

From here we would put that in `server`

```clojure
(server app 8000)
```

And that's pretty much all there is to joy. There are a lot more middleware and helper functions for common web app stuff like redirects, form submission, static files (mostly for dev, since nginx handles that much better in prod), json responses, sessions, and anti-csrf, but they all play by the same rules, there is nothing special about joy's middleware and middleware you write, it's all functions, all the time.
