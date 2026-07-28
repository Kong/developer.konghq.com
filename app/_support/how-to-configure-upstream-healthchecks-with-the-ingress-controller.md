---
title: How to configure upstream healthchecks with the Ingress Controller
content_type: support
description: Explains how to configure upstream circuit breakers and active healthchecks through the Kong Ingress Controller, covering both the legacy `KongIngress` resource (KIC 2.5/2.12 LTS) and the annotation-based approach (KIC 3.1+).
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure upstream circuit breakers and active healthchecks with the Kong Ingress Controller?
  a: |
    For KIC 2.5 LTS/2.12 LTS, define a `KongIngress` resource with `upstream.healthchecks` (passive and active) and reference it from the Kubernetes Service using the `konghq.com/override` annotation. For KIC 3.1 and onwards, `KongIngress` is removed in favor of annotations and the `KongUpstreamPolicy` custom resource, which cover the same healthcheck configuration.
related_resources:
  - text: Gateway Upstream healthchecks documentation
    url: /gateway/how-kong-works/health-checks
  - text: KongIngress upstream-policy annotation reference (KIC 3.1+)
    url: /kubernetes-ingress-controller/reference/annotations/#konghqcomupstream-policy
  - text: KongUpstreamPolicy custom resource reference (KIC 3.1+)
    url: /kubernetes-ingress-controller/reference/custom-resources/#kongupstreampolicy
---

## Overview

When using the Kubernetes Ingress Controller and defining the Kong Objects using the Kubernetes Ingress resource, how can I define circuit breakers and active healthchecks?

## Steps

### For KIC versions 2.5 LTS and 2.12 LTS

If you need to configure circuit breakers and active healthchecks in Kubernetes, you can do it using the `KongIngress` resource object and annotating the Kubernetes Service object so that it references the defined `KongIngress`. As this is changing the upstream parameters, the annotation needs to go on the Kubernetes Service and not on the Ingress.

Once the Service has been annotated to use the `KongIngress` object that has been set with the upstream healthcheck parameters, Kong will update the upstream objects accordingly and provide the passive healthchecks (circuit breakers) and active healthchecks should you require them.

For example, you can define the following `KongIngress`:

```yaml

apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: sample-kong-ingress
upstream:
  hash_on: header
  hash_on_header: x-lb
  hash_fallback: ip
  algorithm: consistent-hashing
  healthchecks:
    passive:
      healthy:
        successes: 1
      unhealthy:
        http_failures: 5
        tcp_failures: 5
        timeouts: 3
    active:
      healthy:
        interval: 10
        successes: 1
      unhealthy:
        interval: 10
        http_failures: 5
        tcp_failures: 5
        timeouts: 3
```

Then, you need to annotate the Kubernetes Service as `konghq.com/override` so that the upstream gets configured accordingly:

```yaml

annotations:
  konghq.com/override: sample-kong-ingress
```

You can find the Gateway Upstream healthchecks documentation in the related resources below.

### For KIC version 3.1 and onwards

For Kubernetes Ingress Controller 3.1 and onwards, `KongIngress` is going to be removed and it is replaced with annotations in most cases, including healthchecks. See the annotation and custom resource references below.
