# Form Submission

Let's talk about form submission. Usually it wouldn't matter, but since we've been hacking forms into the web for that last few decades, things have gotten a little complicated. We have things like XSS and CSRF which thankfully are built into joy.

## Submitting a form with no protection

This is pretty much all you need to have a working form

```clojure
[:form {:method "post" :action "/"}
  [:input {:type "text" :name "username"}]]
```

This outputs

```html
<form method="post" action="/">
  <input type="text" name="username" />
</form>
```

Of course this is vulnerable to CSRF so we should soup it up a little bit

```clojure
(import joy)

(defn new [request]
  (joy/form-for [request :create]
    [:input {:type "text" :name "username"}]))

(joy/defroutes routes
  [:get "/" new])
```

At this point you're going to need a `.env` file with an `ENCRYPTION_KEY` in it or set an `ENCRYPTION_KEY` in your os environment:

```clojure
(import cipher)

(os/setenv "ENCRYPTION_KEY" (cipher/encryption-key))
```

This is looking much better, along with the rest of a few of joy's middleware functions this will send a csrf token along with the form:

```html
<form method="post" action="/">
  <input type="text" name="username" />
  <input type="hidden" name="csrf-token" value="some long base64 encoded string" />
</form>
```

I waved away some of the complexity that's associated with generating that token, but a more complete example is below:

```clojure
(import joy)
(import json)

(defn create [{:body body}]
  (let [name (get body :username)]
    (joy/render :json (json/encode {:username name}))))

(defn new [request]
  (joy/form-for [request :create]
    [:input {:type "text" :name "username"}]))

(joy/defroutes routes
  [:get "/" new]
  [:post "/" create])

(def app (-> (joy/handler routes)
             (joy/csrf-token)
             (joy/sessions)
             (joy/body-parser)))
```

There we go, a few bells and whistles and middleware and now `form-for` is (hopefully) as secure as it can be! The CSRF token is sent with the form and encrypted in the session cookie.

Also `body-parser` was included because otherwise we can't actually parse the body, go figure.
