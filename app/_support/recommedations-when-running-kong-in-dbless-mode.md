---
title: Recommendations when running Kong in DBless mode
content_type: support
description: Best practices for sizing `nginx_worker_processes`, compute resources, and `mem_cache_size` when running Kong Gateway in DB-less mode.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: nginx_worker_processes directive
    url: /gateway/configuration/#nginx-worker-processes
  - text: mem_cache_size directive
    url: /gateway/configuration/#mem-cache-size
tldr:
  q: Are there any resource considerations when running Kong in DBless mode?
  a: |
    Yes. Set `nginx_worker_processes` to at least two, provision enough compute for the added workers, size the in-memory cache with `mem_cache_size` in `kong.conf`, and keep declarative configuration small by using plugins efficiently.
---

## Problem

There are resource considerations to account for when running Kong in DBless mode.

## Solution

Please follow these best practices to avoid request latency or performance issues.

1. Set `nginx_worker_processes` to a minimum of two (2) or more.
   Set the `nginx_worker_processes` directive in `kong.conf`.
2. Provide enough Compute resources to handle the increased number of workers.
   One CPU per Worker Process
3. Make sure that the in-memory cache is configured appropriately.
   Set the `mem_cache_size` directive in `kong.conf`.
4. Deploy Kong plugins efficiently to keep the K8s Declarative Configuration as small as possble.

Please refer to the latest documentation:
