# Authentication

Joy doesn't have an authentication library (yet), but in the mean time here is a pretty good example of how you can add sign up/sign in/sign out to your project

## Creating a database table for accounts

The first step in this unfortunate multi-step process is to create a new table "account" with email and password columns:

```sh
joy create table account 'email text unique not null' 'password text not null'
joy migrate
```

Don't forget to migrate!

## Creating new accounts

The next step is to set up routes and handlers to let people sign up and one more route to redirect people after signing in/up.

For this next bit you're going to need another library in your `project.janet` file, [cipher](https://github.com/joy-framework/cipher) for hashing the passwords.

*src/routes/account.janet*
```clojure
(import joy :prefix "")
(import joy/base64 :as base64)
(import cipher)


(def params
  (params
    (validates [:email :password] :required true)
    (permit [:email :password])))


(defn new [request]
  (let [account (get request :account {})]
    (form-for [request :account/create]
      (label :email "email")
      (email-field account :email)

      (label :password "password")
      (password-field account :password)

      (label :confirm-password "confirm your password")
      (password-field account :confirm-password)

      (submit "save"))))


(defn hash-password [dict]
  (let [{:password password} dict
        key (-> (env :encryption-key) (base64/decode))
        new-password (-> (cipher/hash-password key password)
                         (base64/encode))
    (merge dict {:password new-password})))


(defn create [request]
  (let [{:db db} request
        result (->> (params request)
                    (hash-password)
                    (insert db :account)
                    (rescue))
        [errors account] result
        account (select-keys account [:email])]

    (if errors
      (new (put request :errors errors))
      (-> (redirect-to :home/index)
          (put :session {:account account})))))
```

Then over in your routes file add those two handlers

*src/routes.janet*

```clojure
(use joy)
(import ./src/routes/home :as home)
(import ./src/routes/account :as account)

(defroutes routes
  [:get "/" home/index]
  [:get "/sign-up" account/create]
  [:post "/accounts" account/create])
```

## Hashing passwords

In case you didn't catch it before, this is the bit where we hash passwords. It's kind of involved, but it works.

```clojure
(defn hash-password [dict]
  (let [{:password password} dict
        key (-> (env :encryption-key) (base64/decode))
        new-password (-> (cipher/hash-password key password)
                         (base64/encode))
    (merge dict {:password new-password})))
```

## Signing accounts in

*src/routes/session.janet*

```clojure
(import joy :prefix "")
(import joy/base64 :as base64)
(import cipher)


(def params
  (params
    (validates [:email :password] :required true)
    (permit [:email :password])))


(defn new [request]
  (let [account (get request :account {})
        errors (get request :errors {})]

    (form-for [request :session/create]
      (label :email)
      (email-field account :email)
      (when errors [:div {:class "red"} (get errors :email)])

      (label :password)
      (password-field account :password)
      (when errors [:div {:class "red"} (get errors :password)])

      (submit "Save"))))


(defn password-matches? [hashed plaintext]
  (cipher/verify-password (codec/decode (env :encryption-key))
                          (codec/decode (get hashed :password))
                          (get plaintext :password)))


(defn create [request]
  (let [{:db db} request
        [_ account-params] (rescue (params request))
        email (get account-params :email)
        account (-> (from db :account :where {:email email} :limit 1)
                    (get 0))]

    (if (and (not (nil? account))
             (password-matches? account account-params))
      (-> (redirect-to :home/index)
          (put :session {:account (select-keys account [:email])}))
      (new (put request :errors {:email "Email or password is incorrect"})))))
```

Not the cleanest code there but don't forget to wire up those routes

```clojure
(use joy)
(import ./src/routes/home :as home)
(import ./src/routes/account :as account)
(import ./src/routes/session :as session)

(defroutes routes
  [:get "/" home/index]
  [:get "/sign-up" account/create]
  [:post "/accounts" account/create]
  [:get "/sign-in" session/create]
  [:post "/sessions" session/create])
```

## Signing accounts out

```clojure
(defn destroy [request]
  (-> (redirect-to :home/index)
      (put :session {})))
```

One day soon this will all be a bad dream and you'll be able to stick one line of authentication middleware in there and have working email/password auth (and possibly google/apple auth as well).

Oh, don't forget to update the routes again 😅


```clojure
(use joy)
(import ./src/routes/home :as home)
(import ./src/routes/account :as account)
(import ./src/routes/session :as session)

(defroutes routes
  [:get "/" home/index]
  [:get "/sign-up" account/create]
  [:post "/accounts" account/create]
  [:get "/sign-in" session/create]
  [:post "/sessions" session/create]
  [:delete "/sessions" session/destroy])
```
