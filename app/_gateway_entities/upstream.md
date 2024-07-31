---
title: Upstreams
entities:
  - upstream

content_type: reference

description: An upstream refers to the service applications sitting behind Kong Gateway, to which client requests are forwarded.
---

## What is an upstream?

{{page.description}} In {{site.base_gateway}}, an upstream represents a virtual hostname and can be used to health check, circuit break, and load balance incoming requests over multiple [target](/gateway/entities/target/) backend services.

## Use cases for upstreams

The following are examples of common use cases for upstreams:

