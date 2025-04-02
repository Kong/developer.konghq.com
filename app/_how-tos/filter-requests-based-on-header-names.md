---
title: Filter requests based on header names
content_type: how_to

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

min_version:
  gateway: '3.4'

plugins:
  - pre-function

entities:
  - service
  - route
  - plugin

tags:
  - routing
  - serverless

tldr:
  q: How do I filter which requests are allowed to pass through based on the presence of a header?
  a: |
   You can use the serverless Pre-Function plugin to detect headers in a request, and either let the request through or terminate it. 
   
   In this tutorial, we'll enable the Pre-Function plugin in the access phase, where it will look for a request with the header `X-Custom-Auth`.
   If the header exists in the request, it lets the request through. If the header doesn’t exist, it terminates the request early.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Enable the Pre-Function plugin

The Pre-Function plugin lets you execute Lua code. In this case, we're using the plugin to look for a specific header, `x-custom-auth`. 

The following example applies the Pre-Function plugin globally, in the access phase:
```yaml
echo '
_format_version: "3.0"
plugins:
  - name: pre-function
    config:
      access:
        - |
            -- Get list of request headers
            local custom_auth = kong.request.get_header("x-custom-auth")

            -- Terminate request early if the custom authentication header
            -- does not exist
            if not custom_auth then
              return kong.response.exit(401, "Invalid Credentials")
            end
' | deck gateway apply -
```

## 2. Validate

Let's test that the code will terminate the request when no header is passed:

{% validation request-check %}
url: '/anything'
status_code: 401
{% endvalidation %}

You should get a `401` status code with the message `Invalid Credentials`.

Now, test the code by making a valid request with the `x-custom-auth` header:

{% validation request-check %}
url: '/anything'
status_code: 200
headers:
- 'x-custom-auth: example'
{% endvalidation %}

This time, the request will pass through and you'll see a `200` response. 