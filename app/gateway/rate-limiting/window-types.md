---
title: Rate Limiting Window Types

description: This page describes the rate limiting window types supported by {{site.base_gateway}} plugins.

content_type: reference
layout: reference

related_resources:
  - text: Rate Limiting
    url: /rate-limiting/

plugins:
  - rate-limiting-advanced
  - ai-rate-limiting-advanced
  - graphql-rate-limiting-advanced

products:
  - gateway

tier: enterprise

breadcrumbs:
  - /gateway/
  - /gateway/rate-limiting/
---

The Rate Limiting Advanced, AI Rate Limiting Advanced, and GraphQL Rate Limiting Advanced plugins support the following window types:

* **Fixed window**: Fixed windows consist of buckets that are statically assigned to a definitive time range. Each request is mapped to only one fixed window based on its timestamp and will affect only that window’s counters.
* **Sliding window** (default): A sliding window tracks the number of hits assigned to a specific key (such as an IP address, consumer, credential) within a given time window, taking into account previous hit rates to create a dynamically calculated rate.
The default (and recommended) sliding window type ensures a resource is not consumed at a higher rate than what is configured.

For example, consider this configuration:

* Limit size = 10
* Window size = 60 seconds

With a fixed window type, you can predict when the window is going to be reset and if the client sends a burst of traffic. For example, if 12 requests arrive in one minute, 10 requests are accepted with a `200` response and two requests are rejected with a `429` response.

If you use a sliding window, the first instance is the same: the client sends a burst of 12 requests per minute, 10 requests are accepted with a `200` response and two requests are rejected with a `429` response. 
In this case, it appears to the client that the window is never reset.
The algorithm counts the response `429` and the API is blocked indefinitely.
This happens because the burst of traffic rate of 12 requests per minute is higher than the rate configured in the plugin, which is 10 requests per minute. 
If the client reduces the number of requests, then you get the `response 200` again.

When the client receives a `429` response, it also receives a `Retry-After:<seconds>` header. This means the client has to wait some number of seconds before making a new request. 
If the client makes another request in less than this time, you get the `429` response again. Otherwise, the window is reset.

The sliding window type ensures the API is consumed in the configured requests per second rate. 
This is not always true for the fixed window strategy. 

Consider the same example with 10 requests per minute instead of 12. 
Let's say the client sends all 10 requests in the 59th second of the window:
* In a fixed window, the window resets a second later, and the client can send another 10 requests in the first second of the following window. All of the requests are accepted, making the acceptance rate higher than the configured rate in that two-second time period.
* In a sliding window, the window moves during the last 60 seconds to ensure it meets the configured rate.