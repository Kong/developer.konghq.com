---
title: How to view the contents of shared dictionaries
content_type: support
description: Use a pre-function plugin to report the contents of the SHM LRU dictionaries in Kong.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I view the contents of the shared dictionaries in Kong?
  a: |
    Use a `pre-function` plugin to report the contents of the SHM LRU dictionaries. The Lua code calls
    `ngx.shared["kong_rate_limiting_counters"]:get_keys(2000)` to fetch the first 2000 keys from the dictionary
    and logs each key with `kong.log.err`. The retrieved keys then appear in the Kong error log.
related_resources: []
---

## Overview

How do you see the contents of the shared dictionaries?

## Steps

Use a `pre-function` plugin to report the contents of the SHM LRU dictionaries in Kong.

The following examples show `pre-function` plugin code that inspects the `kong_rate_limiting_counters` dictionary for the first 2000 keys.

The Lua code:

```lua
kong.log.err("PRE FUNCTION EXECUTED")
local keys, err = ngx.shared["kong_rate_limiting_counters"]:get_keys(2000)
if not keys then
   kong.log.err("cannot fetch keys in shared dict! ", err)
else
   kong.log.err("keys retrieved: ", #keys)
   for k, v in pairs(keys) do
       kong.log.err(k, v)
   end
end
kong.log.err("PRE FUNCTION ENDED")
```

K8s plugin code:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: capture-kong-locks-pre-function
config:
  access:
  - |
    kong.log.err("PRE FUNCTION EXECUTED")
    local keys, err = ngx.shared["kong_rate_limiting_counters"]:get_keys(2000)
    if not keys then
      kong.log.err("cannot fetch keys in shared dict! ", err)
    else
      kong.log.err("keys retrieved: ", #keys)
      for k, v in pairs(keys) do
        kong.log.err(k, v)
      end
    end
    kong.log.err("PRE FUNCTION ENDED")
plugin: pre-function
```

The result in the Kong log:

```text
2023/02/06 07:44:30 [error] 2207#0: *990 [kong] [string "kong.log.err("PRE FUNCTION EXECUTED")..."]:6 [pre-function] keys retrieved: 4, client: 172.18.0.1, server: kong, request: "GET /bin HTTP/1.1", host: "localhost:8000"
2023/02/06 07:44:30 [error] 2207#0: *990 [kong] [string "kong.log.err("PRE FUNCTION EXECUTED")..."]:8 [pre-function] 1jLcEZU3Fr004xsxam1jELW07UfLf8D7p|1675669469|1|172.18.0.1|diff, client: 172.18.0.1, server: kong, request: "GET /bin HTTP/1.1", host: "localhost:8000"
2023/02/06 07:44:30 [error] 2209#0: *991 [kong] [string "kong.log.err("PRE FUNCTION EXECUTED")..."]:1 [pre-function] PRE FUNCTION EXECUTED, client: 172.18.0.1, server: kong, request: "GET /bin HTTP/1.1", host: "localhost:8000"
2023/02/06 07:44:30 [error] 2207#0: *990 [kong] [string "kong.log.err("PRE FUNCTION EXECUTED")..."]:8 [pre-function] 2jLcEZU3Fr004xsxam1jELW07UfLf8D7p|1675669469|1|172.18.0.1|sync, client: 172.18.0.1, server: kong, request: "GET /bin HTTP/1.1", host: "localhost:8000"
2023/02/06 07:44:30 [error] 2207#0: *990 [kong] [string "kong.log.err("PRE FUNCTION EXECUTED")..."]:8 [pre-function] 3jLcEZU3Fr004xsxam1jELW07UfLf8D7p|1675669470|1|172.18.0.1|diff, client: 172.18.0.1, server: kong, request: "GET /bin HTTP/1.1", host: "localhost:8000"
2023/02/06 07:44:30 [error] 2207#0: *990 [kong] [string "kong.log.err("PRE FUNCTION EXECUTED")..."]:8 [pre-function] 4jLcEZU3Fr004xsxam1jELW07UfLf8D7p|1675669470|1|172.18.0.1|sync, client: 172.18.0.1, server: kong, request: "GET /bin HTTP/1.1", host: "localhost:8000"
2023/02/06 07:44:30 [error] 2207#0: *990 [kong] [string "kong.log.err("PRE FUNCTION EXECUTED")..."]:11 [pre-function] PRE FUNCTION ENDED, client: 172.18.0.1, server: kong, request: "GET /bin HTTP/1.1", host: "localhost:8000"
```
