(import cipher)
(import codec :as base64)
(import ./helper :prefix "")


(defn- xor-byte-strings [str1 str2]
  (let [arr @[]
        bytes1 (string/bytes str1)
        bytes2 (string/bytes str2)]
    (when (= (length bytes2) (length bytes1) 32)
      (loop [i :range [0 32]]
        (array/push arr (bxor (get bytes1 i) (get bytes2 i))))
      (string/from-bytes ;arr))))


(defn- session-token [request]
  (or (get request :csrf-token)
      (os/cryptorand 32)))


(defn- mask-token [unmasked-token]
  (let [pad (os/cryptorand 32)
        masked-token (xor-byte-strings pad unmasked-token)]
    (base64/encode (string pad masked-token))))


(defn- tokens-equal? [form-token session-token]
  (when (and form-token session-token)
    (cipher/secure-compare form-token session-token)))


(defn- request-token [request]
  (or (get-in request [:body :__csrf-token])
      (x-csrf-token request)))


(defn- unmask-token [masked-token]
  (when-let [token (base64/decode masked-token)
             pad (string/slice token 0 32)
             csrf-token (string/slice token 32)]
    (xor-byte-strings pad csrf-token)))


(defn with-csrf-token
  `
  Adds csrf protection to your web apps

  Example:

  (use joy)

  (defn hello [req]
    (text/plain "hello there!"))

  (defroutes routes
    [:get "/" hello])

  (def app (-> (handler routes)
               (with-csrf-token)
               (with-session))) # You need sessions to store the token somewhere

  (server app 9001)
  `
  [handler]
  (fn [request]
    (let [session-token (session-token request)
          masked-token (mask-token session-token)
          request (merge request {:masked-token masked-token})]
       (if (or (get? request) (head? request))
         (when-let [response (handler request)]
           (merge response {:csrf-token session-token}))

         (let [form-token (unmask-token (request-token request))]
           (if (tokens-equal? form-token session-token)
             (when-let [response (handler request)]
               (merge response {:csrf-token session-token}))
             @{:status 403 :body "Invalid CSRF Token" :headers @{"Content-Type" "text/plain"}}))))))

(def csrf-token with-csrf-token)


(defn csrf-token-value
  `
  Takes a request dictionary and returns the masked token for use
  in meta tags or hidden form fields

  Example:

  (use joy)

  (def request {:method :get :uri "/"})

  (authenticity-token request) => "aGVsbG8gd29ybGQ="
  `
  [request]
  (get request :masked-token))

(def authenticity-token csrf-token-value)


(defn csrf-field
  `
  Takes a request dictionary and returns the tuple html for the hidden form field

  Example:

  (use joy)

  (def request {:method :get :uri "/"})

  (csrf-field request) => [:input {:type "hidden" :name "__csrf-token" :value "aGVsbG8gd29ybGQ="}]
  `
  [request]
  [:input {:type "hidden" :name "__csrf-token" :value (get request :masked-token)}])
