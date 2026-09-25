---
title: Rate Limiting Advanced value storage format in Redis
content_type: support
description: "Explains how the Rate Limiting Advanced plugin stores request counts in Redis as a hash keyed by epoch timestamp, `config.window_size`, and `config.namespace`, with `config.identifier` values as the hash fields."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How does Rate Limiting Advanced store values in Redis?
  a: |
    The plugin stores counts in a Redis hash keyed by `<epoch-timestamp>:<config.window_size>:<config.namespace>`, with hash fields for each tracked identifier (IP, credential, consumer, service, header, or path) holding the request count for that window. Fixed windows use one key per whole window period; sliding windows track multiple overlapping periods and combine them to calculate the current count.
related_resources:
  - text: convert this to a human readable form
    url: https://www.epochconverter.com/
  - text: the plugin configuration
    url: /plugins/rate-limiting-advanced/reference/#schema--config-namespace
  - text: the Admin API
    url: /gateway/admin-api/#/operations/list-plugin-in-workspace
  - text: Rate limiting window types
    url: /gateway/rate-limiting/window-types/
---

## Rate Limiting Advanced value storage format in Redis

When using the Rate Limiting Advanced plugin backed by Redis you may wish to extract data around these limits outside of the scope of the headers returned to the client when a consumer makes a request to a Rate Limited endpoint. How to associate the data in Redis to a given Identifier (such as consumer, or service) and/or plugin?

This information is stored as a Hash in Redis with the `config.identifier` and number of requests within the window stored as the hash values, and the following format for the key:

```
<epoch-timestamp>:<config.window_size>:<config.namespace>
```

Like the following Example:

```
1664978760:60:example-namespace
```

1664978760 = The Epoch Timestamp for the window in question.

60 = The window size in seconds as per `config.window_size`.

example-namespace = the value set for `config.namespace` as per the plugin configuration; this will default to an auto-generated string if not explicitly set.

Within this hash will be a number of values relating to the counters for each individual entry being tracked by the plugin instance. This could be ip, credential, consumer, service, header, or path. This will either be a direct value (such as in the case of selecting IP) or the UUID of whatever record type was set in `config.identifier` (such as a consumer).

For fixed window types the epoch will be the last whole window period, for example if you set the window to 60 seconds and send a request at 07:01:30hrs the epoch timestamp will be for 07:01:00. Once the window has expired a new key will be generated and further requests will be incremented into the value of the new key.

For sliding window types this will be much the same, but there will be multiple epoch timestamps representing the current and previous sliding window period, and the total number of requests will be calculated based off the values of these multiple entries. See Rate limiting window types for more detail on how sliding windows are calculated.

To trace back to the specific plugin in use you can use the value of the namespace to iterate over the configured plugins in the Admin API to confirm the specific plugin to which the request relates.
