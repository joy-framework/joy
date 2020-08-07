# Middleware

When you start a new joy project, the default middleware stack is abstracted away from you with the `app` function

```clojure
(def app (app {:layout layout}))
```

If you need more control or you aren't afraid of sharp edges or debugging middleware order issues for a while, here is what the `app` function looks like under the covers:

```clojure
(use joy)

(def app (-> (handler routes)
             (layout)
             (with-before-middleware)
             (with-after-middleware)
             (csrf-token)
             (session)
             (extra-methods)
             (query-string)
             (body-parser)
             (json-body-parser)
             (server-error)
             (x-headers)
             (static-files)
             (not-found)
             (logger)))
```

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
