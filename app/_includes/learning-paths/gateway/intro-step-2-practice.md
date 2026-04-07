Building on the Service and Route you created in Step 1, you'll now attach two plugins: **Rate Limiting** to cap request volume, and **Key Auth** to require an API key.

## Prerequisites

- The `kong.yaml` and running container from Step 1

## Step 1: Add the Rate Limiting plugin

Update `kong.yaml` to attach the plugin to the Route:

```yaml
_format_version: "3.0"

services:
  - name: httpbin
    url: https://httpbin.konghq.com
    routes:
      - name: httpbin-route
        paths:
          - /httpbin
        plugins:
          - name: rate-limiting
            config:
              minute: 5
              policy: local
```

Sync the configuration:

```bash
deck gateway sync kong.yaml --kong-addr http://localhost:8001
```

Send more than five requests within a minute — after the fifth, {{site.base_gateway}} returns `429 Too Many Requests`.

## Step 2: Add Key Auth

Add the Key Auth plugin on the same Route and create a Consumer with a key:

```yaml
_format_version: "3.0"

consumers:
  - username: alice
    keyauth_credentials:
      - key: my-secret-key

services:
  - name: httpbin
    url: https://httpbin.konghq.com
    routes:
      - name: httpbin-route
        paths:
          - /httpbin
        plugins:
          - name: rate-limiting
            config:
              minute: 5
              policy: local
          - name: key-auth
```

Sync again:

```bash
deck gateway sync kong.yaml --kong-addr http://localhost:8001
```

Now test with and without the key:

```bash
# Without key → 401 Unauthorized
curl -i http://localhost:8000/httpbin/get

# With key → 200 OK
curl -i http://localhost:8000/httpbin/get -H "apikey: my-secret-key"
```

## What you did

- Applied the Rate Limiting plugin at the Route scope
- Added Key Auth to require API key credentials
- Created a Consumer with a credential
- Confirmed that unauthenticated requests are rejected

## Next steps

- Add [Proxy Cache](/hub/kong-inc/proxy-cache/) to cache upstream responses
- Explore [Plugin Hub](/hub/) for the full list of available plugins
- Learn about [custom plugins](/custom-plugins/) to extend the gateway with your own logic
