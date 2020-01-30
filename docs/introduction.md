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
  (render :text (string "hello " (get-in request [:params :name]))))
```

This is a just a janet function, it takes a request dictionary and returns a response dictionary, the `(render)` function is just sugar for `{:status 200 :body "hello!"}` which is the janet dictionary literal.

## Routes

```clojure
(defroutes hello-routes
  [:get "/" home]
  [:post "/" sweet-home]
  [:get "/hello/:name" hello])
```

Those are routes, they take any number of tuples in the form of

`[:http-verb "/route/string" name-of-handler-function :optional-alias-of-function]`

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

## Middleware Explained

The simplicity of this model is really nice but there are a few downsides:

1. Middleware gets called "backwards"
2. There is a way to stop a middleware stack from being called, but you'd have to resolve the route at the "bottom" of the stack

Since the logger middleware gets called "around" the handler function that was passed in, it effectively gets called first, even though
it looks like it gets called last thanks to the thread first macro `->`.

The other problem where you can't stop middleware execution and return something else (like a 500 response) is also problematic when it comes to trying to give different routes different middleware like auth or admin middleware or even api middleware when you have an api along with your traditional html returning web app.

Joy makes these trade offs for the simplicity and gets around problem 2 by offering a "skip" middleware, which essentially can be put on the bottom (or called last) in the web middleware stack and calls the routes first and merges "has this route matched key" to the request which other middleware can inspect and decide to skip processing to speed up large, middleware heavy apps.

In practice though, you typically only have a few middleware stacks Like

- auth
- admin routes
- the default joy web stack
- and maybe an api stack (without all the cookie/session/csrf/html rendering stuff)

so in the worst case (an admin route), you'd be calling four middleware stacks which could be about 20 functions total, not the end of the world, considering how many functions typically get called in a web framework.

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