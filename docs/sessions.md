# Sessions

Sessions in joy are persisted in an encrypted cookie and set with `SameSite=Strict`, `HttpOnly` and `Path=/`

## Adding data to the session

In a given handler, how do you add data to the session? Here's how:

```clojure
(use joy)

(defn home-page [request]
  (let [name (get-in request [:session :name])]
    [:div (string "welcome to the home page " name])))

(defn add-to-session [request]
  (let [name (get-in request [:params :name])]
    (-> (redirect-to :home-page)
        (put :session {:name name}))))

(defroutes routes
  [:get "/" home-page]
  [:get "/set-name/:name" add-to-session])

(def app (-> (handler routes)
             (session)))
```

Here we see how to take a url parameter `:name` get it out of the params dictionary in request and then put it into the session. You don't need to redirect, it's just a convenience thing and usually you're setting the session on a redirect not a regular 200 response.

Another way to see it is this:

```clojure
(defn add-to-session [request]
  (let [name (get-in request [:params :name])]
    {:status 200 :body " " :headers @{"Location" "/"} :session {:name name}}))
```

Always good to see the bare data.

## Removing data from the session

Likewise you can remove data from the session similarly:

```clojure
(-> (redirect-to :home-page)
    (put :session {}))
```


