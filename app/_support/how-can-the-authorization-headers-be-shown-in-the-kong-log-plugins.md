---
title: Showing Authorization headers in the Kong log plugins
content_type: support
description: Log plugins redact the Authorization header by default; use `custom_fields_by_lua` to log its value to a separate field for debugging.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the Authorization headers be shown in the Kong log plugins?
  a: |
    Log plugins redact the Authorization header and there is no config option to unredact it.
    Use `custom_fields_by_lua` to log the value into a separate field, for example returning `kong.request.get_header("authorization")` into a field such as `x-original-authorization`. Disable the plugin once debugging is done, given the security exposure.
related_resources: []
---

## Overview

When sending Authorization headers, the values for these headers are redacted when using one of the logging plugins. The log shows entires like this;

```json
"headers": {
  "authorization": "REDACTED",
}
```

For debugging purposes, it is sometimes necessary to log the actual values. Can this behavior be controlled via a configuration parameter?

## Steps

There is no configuration option available to log the value of the Authorization headers. It is possible to use the `custom_fields_by_lua` feature to log the values to a different custom field. For example, you could set a log field called `x-original-authorization` and set this to the value for the Authorization using the Kong PDK.

As an example, the `udp-log` plugin could be configured like this;

```bash
curl -s -X POST 'https://api.kong.lan:8444/default/routes/{% raw %}{{routeName}}{% endraw %}/plugins/' \
-H 'Content-Type: application/json' \
--data-raw '{
    "tags": [
        "plugin-example"
    ],
    "name": "udp-log",
    "config": {
        "custom_fields_by_lua": {
            "x-original-authorization": "return kong.request.get_header(\"authorization\")"
        },
        "timeout": 10000,
        "port": 5555,
        "host": "udp-log-hostname"
    }
}'
```

Calling the Route with an Authorization header;

```bash
curl -H "Authorization: fred123" http://proxy.kong.lan/echo
```

will still log the REDACTED value for the Authorization header, but there will also be an extra entry in the log showing the complete value sent for the Authorization header;

```json
  "x-original-authorization": "fred123"
```

Note, there is a potential security implication of saving the Authentication headers, please ensure that you are comfortable with logging these values and disable/delete the plugin once you have completed the debugging.
