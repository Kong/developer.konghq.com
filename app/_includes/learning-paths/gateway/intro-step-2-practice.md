Building on the Service and Route you created in Step 1, you'll now attach two plugins: **Rate Limiting** to cap request volume, and **Key Auth** to require an API key.

## Step 1: Add the Rate Limiting plugin

Attach Rate Limiting to the `httpbin-route` Route. This limits each client to 5 requests per minute:

{% entity_example %}
type: plugin
data:
  name: rate-limiting
  route: httpbin-route
  config:
    minute: 5
    policy: local
{% endentity_example %}

Send more than five requests within a minute — after the fifth, {{site.base_gateway}} returns `429 Too Many Requests`.

## Step 2: Add Key Auth

Enable Key Auth on the same Route to require an API key on every request:

{% entity_example %}
type: plugin
data:
  name: key-auth
  route: httpbin-route
{% endentity_example %}

## Step 3: Create a Consumer with a credential

Create a Consumer named `alice` and issue her an API key:

{% entity_examples %}
entities:
  consumers:
    - username: alice
      keyauth_credentials:
        - key: my-secret-key
{% endentity_examples %}

## Step 4: Verify authentication

Test that unauthenticated requests are rejected and authenticated ones succeed:

```bash
# Without key → 401 Unauthorized
curl -i http://localhost:8000/httpbin/get

# With key → 200 OK
curl -i http://localhost:8000/httpbin/get -H "apikey: my-secret-key"
```

## What you did

- Applied Rate Limiting at the Route scope
- Added Key Auth to require API key credentials
- Created a Consumer with a credential
- Confirmed that unauthenticated requests are rejected
