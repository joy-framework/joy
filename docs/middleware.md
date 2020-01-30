# Middleware

If you make a new joy app from the command line with `joy new` you'll notice `app.janet` has quite a few things hanging around that look like this:

```clojure
(use joy)

(def app (-> (handler routes/app)
             (db (env :db-name))
             (layout layout/app)
             (logger)
             (csrf-token)
             (session)
             (extra-methods)
             (query-string)
             (body-parser)
             (server-error)
             (x-headers)
             (static-files)
             (not-found)))
```

The first thing I want to say is `(use joy)` is a shortcut for `(import joy :prefix "")` and it overrides any default janet functions with joy functions and it allows you to call joy functions with prefixing with `joy/`.

Now let's talk about middleware and why we need such a huge stack of it.

## It's all functions

Here's the simplest example of a middleware function

```clojure
(defn some-middleware [handler]
  (fn [request]
    (handler request)))
```

This middleware function doesn't do anything, but it's the simplest example of how middleware works.
The first thing you'll notice is that unlike route handlers, middleware don't return an http response, instead they return a function that will return the http response 🤯

What's the point, right? The point is to create a layer between the route handlers and any system-wide configuration or behavior that should happen, "cross-cutting concerns" I think it's called in certain circles.

Take a more practical example, logging:

```clojure
(defn logger [handler &opt options]
  (default options {:ignore-keys [:password :confirm-password]})
  (fn [request]
    (let [start-seconds (os/clock)
          response (handler request)
          end-seconds (os/clock)]
      (when response
        (log (request-struct request options))
        (log (response-struct request response start-seconds end-seconds)))
      response)))
```

There's a lot going on there, this is joy's actual logging middleware. It's only what... 10 lines? yet it packs a punch

1. It ignores certain values like passwords and allows you to pass in your own keys you'd like ignored
2. It also executes the handler function in between two timestamp functions for logging response duration
3. Finally it logs the response with the duration in [logfmt](https://www.brandur.org/logfmt) style

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

