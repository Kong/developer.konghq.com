---
title: Adjust header names in a request
permalink: /how-to/adjust-header-names-in-request/
content_type: how_to

description: Change the names of headers sent in a request using the Post-Function plugin.

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck
search_aliases: 
  - post function
breadcrumbs: 
  - /gateway/
prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
related_resources:
- text: Post Function plugin
  url: /plugins/post-function/
min_version:
  gateway: '3.4'

plugins:
  - post-function
  - rate-limiting

entities:
  - service
  - route
  - plugin

tags:
  - headers
  - serverless
  - rate-limiting

tldr:
  q: How do I adjust request header names from multiple sources?
  a: |
   You can use the serverless Post-Function plugin to detect headers in a request and transform them into custom header names.

   In this tutorial, we'll edit two types of headers: headers set by a plugin (in this case, Rate Limiting), and latency headers from {{site.base_gateway}}.
   
   We'll enable the Post-Function plugin in the `header_filter` phase, where it will look for a configured list of headers, then transform those headers into different names.
   The upstream service then only sees the transformed header names.
  
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable the Rate Limiting plugin

Add a [Rate Limiting](/plugins/rate-limiting/) plugin to the `example-service` you created in the [prerequisites](#prerequisites):

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      service: example-service
      config:
        second: 5
        minute: 30
        policy: local
{% endentity_examples %}

## Create a header transformation Lua function

The [Post-Function](/plugins/post-function/) plugin lets you execute Lua code. 
We'll pass a function that renames the following headers:

* **Rate limiting headers**: The Rate Limiting plugin returns headers such as `X-RateLimit-Remaining-{time}` and `X-RateLimit-Limit-{time}`, 
where `{time}` is the configured time span for the limit.
* **Latency headers**: {{site.base_gateway}} adds latency headers to responses, such as `X-Kong-Upstream-Latency` and `X-Kong-Proxy-Latency`.
While you can turn these headers on or off in `kong.conf`, they have fixed names that can't be configured. 

Run the following command to create a `rename-headers.lua` file:

```lua
cat <<EOF > rename-headers.lua
return function()

      local kong_rl_headers = {}
      kong_rl_headers["x-ratelimit-limit-second"]="X-Rlls"
      kong_rl_headers["x-ratelimit-remaining-second"]="X-Rlrs"
      kong_rl_headers["x-ratelimit-limit-minute"]="X-Rllm"
      kong_rl_headers["x-ratelimit-remaining-minute"]="X-Rlrm"
      kong_rl_headers["x-ratelimit-limit-hour"]="X-Rllh"
      kong_rl_headers["x-ratelimit-remaining-hour"]="X-Rlrh"
      kong_rl_headers["x-ratelimit-limit-day"]="X-Rlld"
      kong_rl_headers["x-ratelimit-remaining-day"]="X-Rlrd"
      kong_rl_headers["x-ratelimit-limit-month"]="X-Rlln"
      kong_rl_headers["x-ratelimit-remaining-month"]="X-Rlrn"
      kong_rl_headers["x-ratelimit-limit-year"]="X-Rlly"
      kong_rl_headers["x-ratelimit-remaining-year"]="X-Rlry"

      local headers = kong.response.get_headers()
      for k, v in pairs(headers) do
        if kong_rl_headers[k] ~= nil then
          kong.response.set_header(kong_rl_headers[k], v)
          kong.response.clear_header(k)
        end
      end

      -- Add custom headers for latency
      kong.response.set_header("My-Custom-Proxy-Latency", ngx.ctx.KONG_PROXY_LATENCY)
      kong.response.set_header("My-Custom-Upstream-Latency", ngx.ctx.KONG_WAITING_TIME)

    end
EOF
```

Add the `rename-headers.lua` file as a decK environment variable so that you can pass this file to decK:

```sh
export DECK_RENAME_HEADERS="$(cat rename-headers.lua)"
```

## Enable the Post-Function plugin

To change the header names, set up a Post-Function plugin instance that runs globally in the `header_filter` phase, and pass the function as an environment variable:

```yaml
echo '
_format_version: "3.0"
plugins:
- name: post-function
  route: example-route
  config:
    header_filter:
      - |
         {% raw %}${{ env "DECK_RENAME_HEADERS" | indent 8 }}{% endraw %}
' | deck gateway apply -
```

## Validate

Let's test that the response header names have changed:

{% validation request-check %}
url: '/anything'
status_code: 200
display_headers: true
{% endvalidation %}

The response should show the new header names.