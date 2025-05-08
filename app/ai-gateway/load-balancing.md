---
title: "Load balancing with AI gateway [WIP]"
layout: reference
content_type: reference
description: This guide provides an overview of load balancing and reatry and fallback strategies in AI Proxy Advanced plugin.

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway

tags:
  - ai
  - streaming

plugins:
  - ai-proxy-advanced

min_version:
  gateway: '3.10'

---

## AI Load balancing

Kong AI Gateway provides advanced load balancing capabilities to efficiently distribute requests across multiple LLM models. It ensures fault tolerance, efficient resource utilization, and load distribution across AI models

The plugin supports several load balancing algorithms, similar to those used for Kong upstreams, and extends them for AI model routing. Kong AI Gateway uses the [Upstream entity](/gateway/entities/upstream/) to configure load balancing, offering multiple algorithm options to fine-tune traffic distribution to various AI Providers and LLM models.


### Overview



### Retry and fallback

The load balancer includes built-in support for **retries** and **fallbacks**. When a request fails, the balancer can automatically retry the same target or redirect the request to a different upstream target.

This functionality is critical for maintaining service reliability, especially when working with multiple model providers or distributed systems.


## How retry and fallback works

1. Client sends a request.
2. The load balancer selects a target based on the configured algorithm (e.g., round-robin, lowest-latency).
3. If the target fails (based on defined `failover_criteria`), the balancer:

   * **Retries** the same or another target.
   * **Fallbacks** to another available target.
4. If retries are exhausted without success, the load balancer returns a failure to the client.

## Retry and fallback configuration

The AI Gateway load balancer offers several configuration options to fine-tune request retries, timeouts, and failover behavior.

The table below summarizes the key configuration parameters available:

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: "`retries`"
    description: |
      Defines how many times to retry a failed request before reporting failure to the client.
      Increase for better resilience to transient errors; decrease if you need lower latency and faster failure.
  - setting: "`failover_criteria`"
    description: |
      Specifies which types of failures (e.g., `http_429`, `http_500`) should trigger a failover to a different target.
      Customize based on your tolerance for specific errors and desired failover behavior.
  - setting: "`connect_timeout`"
    description: |
      Sets the maximum time allowed to establish a TCP connection with a target.
      Lower it for faster detection of unreachable servers; raise it if some servers may respond slowly under load.
  - setting: "`read_timeout`"
    description: |
      Defines the maximum time to wait for a server response after sending a request.
      Lower it for real-time applications needing quick responses; increase it for long-running operations.
  - setting: "`write_timeout`"
    description: |
      Sets the maximum time allowed to send the request payload to the server.
      Increase if large request bodies are common; keep short for small, fast payloads.
{% endtable %}
<!--vale on-->

