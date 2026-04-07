In this guide you'll start a local {{site.base_gateway}} instance in DB-less mode, define a Service and Route, and verify that traffic is proxied correctly.

## Step 1: Start {{site.base_gateway}} in DB-less mode

Run a minimal {{site.base_gateway}} container that reads its configuration from a file on startup:

```bash
docker run -d --name kong-gateway \
  -e "KONG_DATABASE=off" \
  -e "KONG_DECLARATIVE_CONFIG=/kong/declarative/kong.yaml" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -v "$(pwd)/kong.yaml:/kong/declarative/kong.yaml" \
  -p 8000:8000 \
  -p 8001:8001 \
  kong/kong-gateway:{{site.latest_gateway_oss_version}}
```

## Step 2: Create a Service

A **Service** points to the upstream API you want to proxy. Create one targeting the public httpbin echo API:

{% entity_example %}
type: service
data:
  name: httpbin
  url: https://httpbin.konghq.com
{% endentity_example %}

## Step 3: Create a Route

A **Route** matches incoming requests and forwards them to the Service. Create one that matches requests with the path prefix `/httpbin`:

{% entity_example %}
type: route
data:
  name: httpbin-route
  paths:
    - /httpbin
  service:
    name: httpbin
{% endentity_example %}

## Step 4: Verify the proxy

Send a request through the gateway:

```bash
curl -i http://localhost:8000/httpbin/get
```

You should receive a `200 OK` response from httpbin with your request details echoed back.

## What you did

- Started {{site.base_gateway}} in DB-less mode
- Created a Service pointing to an upstream API
- Created a Route that proxies `/httpbin` traffic to that Service
- Confirmed the proxy is working end-to-end

Move on to Step 2 to add plugins on top of this setup.
