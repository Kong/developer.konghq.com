In this guide you'll start a local {{site.base_gateway}} instance in DB-less mode, define a Service and Route, and verify that traffic is proxied correctly.

## Prerequisites

- Docker installed and running
- [decK](/deck/) CLI installed (`deck version` should succeed)

## Step 1: Start Kong Gateway in DB-less mode

Run a minimal {{site.base_gateway}} container:

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

## Step 2: Write a declarative configuration

Create a file named `kong.yaml` in your working directory:

```yaml
_format_version: "3.0"

services:
  - name: httpbin
    url: https://httpbin.konghq.com
    routes:
      - name: httpbin-route
        paths:
          - /httpbin
```

This defines one **Service** pointing to a public echo API, and one **Route** matching requests whose path starts with `/httpbin`.

## Step 3: Verify the proxy

Send a request through the gateway:

```bash
curl -i http://localhost:8000/httpbin/get
```

You should receive a `200 OK` response from httpbin with your request details echoed back.

## What you did

- Started {{site.base_gateway}} in DB-less mode with a declarative config file
- Defined a Service and a Route that together proxy traffic to an upstream
- Confirmed the proxy is working end-to-end

Move on to Step 2 to add plugins on top of this setup.
