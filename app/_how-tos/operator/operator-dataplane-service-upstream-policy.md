---
title: Configure load balancing with KongUpstreamPolicy
description: "Learn how to customize load balancing behavior for a Kubernetes Service using the konghq.com/upstream-policy annotation and a KongUpstreamPolicy resource."
content_type: how_to

permalink: /operator/dataplanes/how-to/configure-upstream-policy/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem
  - konnect

min_version:
  operator: '2.2'

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway
    - title: Create a Service and a Route
      include_content: /prereqs/operator/echo-service-route

tldr:
  q: How do I configure custom load balancing behavior for a Service with {{ site.operator_product_name }}?
  a: |
    Create a `KongUpstreamPolicy` resource with your desired load balancing settings, then attach it to the Kubernetes `Service` using the `konghq.com/upstream-policy` annotation.

related_resources:
  - text: Service annotations reference
    url: /operator/dataplanes/reference/service-annotations/
  - text: KongUpstreamPolicy reference
    url: /kubernetes-ingress-controller/reference/custom-resources/#kongupstreampolicy
---

By default, {{site.base_gateway}} distributes requests across the Pods of a Kubernetes Service using round-robin load balancing. For production workloads, you may need sticky sessions, consistent routing based on request attributes, or health check integration.

The `konghq.com/upstream-policy` annotation lets you attach a `KongUpstreamPolicy` resource to a `Service`, giving you full control over {{site.base_gateway}}'s upstream load balancing behavior.

This guide demonstrates consistent-hashing load balancing, which routes requests with the same header value to the same upstream Pod — a common pattern for session affinity.

## Scale the Service

Scale the `echo` Deployment to three replicas so there are multiple Pods to route between:

```bash
kubectl scale deployment echo -n kong --replicas=3
```

Wait for all Pods to be ready:

```bash
kubectl rollout status deployment echo -n kong
```

## Create a KongUpstreamPolicy

Create a `KongUpstreamPolicy` that configures consistent-hashing by a request header:

```bash
echo '
apiVersion: configuration.konghq.com/v1beta1
kind: KongUpstreamPolicy
metadata:
  name: session-affinity
  namespace: kong
spec:
  algorithm: consistent-hashing
  hashOn:
    header: x-session-id
  hashOnFallback:
    input: ip' | kubectl apply -f -
```

With this policy, requests that carry the same `x-session-id` header value are always forwarded to the same upstream Pod. When the header is absent, {{site.base_gateway}} falls back to hashing on the client IP.

## Annotate the Service

Attach the `KongUpstreamPolicy` to the `echo` Service:

```bash
kubectl annotate service echo -n kong \
  konghq.com/upstream-policy="session-affinity"
```

## Validate

1. Get the Gateway's external IP address:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Send several requests with the same `x-session-id` header value and observe that all responses come from the same Pod:

   ```bash
   for i in {1..5}; do
     curl -s -H "x-session-id: user-alice" $PROXY_IP/echo | grep "Running on Pod"
   done
   ```

   All five responses should report the same Pod name:

   ```
   Running on Pod echo-6d8f4c9b7-xk2vt.
   Running on Pod echo-6d8f4c9b7-xk2vt.
   Running on Pod echo-6d8f4c9b7-xk2vt.
   Running on Pod echo-6d8f4c9b7-xk2vt.
   Running on Pod echo-6d8f4c9b7-xk2vt.
   ```
{:.no-copy-code}

1. Send requests with a different header value to confirm they land on a different Pod:

   ```bash
   for i in {1..5}; do
     curl -s -H "x-session-id: user-bob" $PROXY_IP/echo | grep "Running on Pod"
   done
   ```

   Requests for `user-bob` consistently hit a different Pod than requests for `user-alice`.
