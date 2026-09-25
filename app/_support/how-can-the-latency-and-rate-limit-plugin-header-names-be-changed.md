---
title: Renaming or hiding the latency and rate-limiting plugin response headers in Kong Gateway
content_type: support
description: How to hide Kong's fixed-name latency and rate-limiting response headers and replace them with custom-named headers using a post-function plugin.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the latency and rate-limit plugin header names be changed?
  a: |
    Kong's latency and rate-limiting response headers have fixed names that can't be renamed through configuration. Turn off the default headers with the `headers` `kong.conf` parameter, then use a post-function plugin running in the `header_filter` phase to read the existing headers, set custom-named replacements with `kong.response.set_header()`, and clear the originals with `kong.response.clear_header()`.
related_resources:
  - text: Kong Gateway configuration property reference
    url: /gateway/configuration/#headers
---

## Overview

When the classic rate-limiting plugin is added, headers are returned to the client with names such as `X-RateLimit-Remaining-<time>` and `X-RateLimit-Limit-<time>` where `<time>` is the configured time span for the limit, for example seconds, minutes, hours, etc. Since these headers were standardized, Kong also adds a second, IETF-draft-style set of headers alongside them: `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` (and `Retry-After` once the limit is exceeded). Any header-hiding/renaming recipe needs to account for both sets, or the second set will still leak the same rate-limit information.

Also Kong adds latency headers to the response such as `X-Kong-Upstream-Latency` and `X-Kong-Proxy-Latency`.

These headers have fixed names that cannot be altered via a configuration. How can they be changed to different values for the names? This renaming is desirable in some circumstances to limit the information provided to potential hackers.

## Steps

The latency headers (and other informational headers such as `Server`/`Via` tokens and the `X-Kong-Request-Id` header) are controlled via the `headers` `kong.conf` parameter; see the Kong Gateway configuration property reference for the current list of accepted values.

While it is not possible to change the name of these headers, the latency headers can be turned off and custom headers containing the same information can be added using a post-function plugin. Similarly, the rate-limit headers have fixed names, but these can be changed via the same post-function plugin.

The steps to configure Kong and create the post-function plugin are detailed below:

1. Set the `headers` parameter to `off` or some other value that does not return the latency headers by default. Restart Kong to pick up the changed configuration.

2. Create a serverless post-function plugin that runs in the `header_filter` phase. Create a `serverless.lua` file with the following content:

   ```lua
   return function()

   -- Rename rate-limit plugin headers
   -- X-RateLimit-Remaining-second: 1
   -- X-RateLimit-Limit-second: 2
   -- X-RateLimit-Limit-second changed to X-Rlls
   -- X-RateLimit-Remaining-second changed to X-Rlrs
   --
   -- Current Kong versions also emit a second, standardized set of headers
   -- (RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset, Retry-After)
   -- carrying the same information, so these must be renamed/removed too.

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
     kong_rl_headers["ratelimit-limit"]="X-Rl-Limit"
     kong_rl_headers["ratelimit-remaining"]="X-Rl-Remaining"
     kong_rl_headers["ratelimit-reset"]="X-Rl-Reset"
     kong_rl_headers["retry-after"]="X-Rl-Retry-After"

     local headers = kong.response.get_headers()
     for k, v in pairs(headers) do
     	if kong_rl_headers[k] ~= nil then
           kong.response.set_header(kong_rl_headers[k], v)
           kong.response.clear_header(k)
         end
     end

     -- Add custom headers for the latency
     kong.response.set_header("My-Custom-Proxy-Latency", ngx.ctx.KONG_PROXY_LATENCY)
     kong.response.set_header("My-Custom-Upstream-Latency", ngx.ctx.KONG_WAITING_TIME)

   end
   ```

3. Add the serverless function to the appropriate Kong entity. For this example, we are applying to a specific Route:

   ```bash
   curl -XPOST 'https://kong:8444/routes/LocalEcho/plugins' \
   --form 'name=post-function' \
   --form 'config.header_filter=@/tmp/serverless.lua'
   ```

4. Make a call to the API and check the response header names have been changed:

   ```bash
   curl -v http://kong:8000/echo
   *   Trying 10.0.10.1...
   * TCP_NODELAY set
   * Connected to kong (10.0.10.1) port 8000 (#0)
   > GET /echo HTTP/1.1
   > Host: kong:8000
   > User-Agent: curl/8.7.1
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Content-Type: application/json
   < Content-Length: 374
   < Connection: keep-alive
   < Server: gunicorn/19.9.0
   < Date: Thu, 27 Aug 2026 07:15:19 GMT
   < Access-Control-Allow-Origin: *
   < Access-Control-Allow-Credentials: true
   < X-Rlls: 2
   < X-Rllm: 5
   < X-Rlrm: 3
   < X-Rlrs: 1
   < X-Rl-Limit: 5
   < X-Rl-Remaining: 3
   < X-Rl-Reset: 41
   < My-Custom-Proxy-Latency: 1
   < My-Custom-Upstream-Latency: 4
   < Via: 1.1 kong/3.14.0.0-enterprise-edition
   < X-Kong-Request-Id: 6c8b601249ba7c3303faaf687822b827
   <
   {
     "args": {},
     "data": "",
     "files": {},
     "form": {},
     "headers": {
       "Accept": "*/*",
       "Connection": "keep-alive",
       "Host": "10.0.10.1",
       "User-Agent": "curl/8.7.1",
       "X-Forwarded-Host": "kong",
       "X-Kong-Request-Id": "6c8b601249ba7c3303faaf687822b827"
     },
     "json": null,
     "method": "GET",
     "origin": "172.20.0.1",
     "url": "http://kong/anything"
   }
   * Connection #0 to host kong left intact
   ```
