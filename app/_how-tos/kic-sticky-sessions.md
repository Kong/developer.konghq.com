---
title: Manage sticky sessions with KongUpstreamPolicy
short_title: Sticky Sessions
description: "Configure sticky sessions to ensure client requests are routed to the same backend pod using KongUpstreamPolicy"
content_type: how_to

permalink: /kubernetes-ingress-controller/sticky-sessions/

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Advanced Usage

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I configure sticky sessions to route client requests to the same backend pod?
  a: Create a `KongUpstreamPolicy` with the `sticky-sessions` algorithm and attach it to your Service using the `konghq.com/upstream-policy` annotation

related_resources:
  - text: KongUpstreamPolicy reference
    url: /kubernetes-ingress-controller/reference/custom-resources/
  - text: Load balancing algorithms
    url: /gateway/load-balancing/
  - text: Upstream entity reference
    url: /gateway/entities/upstream/
  - text: "Sticky sessions in {{ site.kic_product_name }}"
    url: /kubernetes-ingress-controller/sticky-sessions-reference/
  - text: Configure sticky sessions with drain support
    url: /kubernetes-ingress-controller/sticky-sessions-with-drain-support/

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service
    routes:
      - echo

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg

min_version:
  kic: '3.5'
  gateway: '3.11'
---

## Overview

Sticky sessions, also known as session affinity, ensure that requests from the same client are consistently routed to the same backend pod. This is particularly useful for:

- **Session persistence**: Applications that store session data in memory or local storage
- **Graceful shutdowns**: Allowing existing connections to complete before terminating pods
- **Connection affinity**: Applications that benefit from maintaining state between requests

{% new_in 3.11 %} {{site.base_gateway}} supports sticky sessions through the `sticky-sessions` load balancing algorithm, which uses browser-managed cookies to maintain session affinity.

## Deploy multiple backend pods

To test sticky sessions, you need more than one pod. Scale the `echo` deployment:

```bash
kubectl scale -n kong --replicas 3 deployment echo
```

Verify the pods are running:

```bash
kubectl get pods -n kong -l app=echo
```

## Create a KongUpstreamPolicy

Apply a `KongUpstreamPolicy` resource that enables sticky sessions:

```bash
echo '
apiVersion: configuration.konghq.com/v1beta1
kind: KongUpstreamPolicy
metadata:
  name: sticky-session-policy
  namespace: kong
spec:
  algorithm: "sticky-sessions"
  hashOn:
    input: "none"
  stickySessions:
    cookie: "session_id"
    cookiePath: "/"
' | kubectl apply -f -
```

Explanation of key fields:

- **`algorithm: sticky-sessions`**: Enables the sticky session load balancing algorithm
- **`hashOn.input: "none"`**: Set it to `none` (required for sticky sessions)
- **`stickySessions.cookie`**: Name of the cookie used for session tracking
- **`stickySessions.cookiePath`**: Path for the session cookie (default: `/`)

### Attach policy to your service

Associate the `KongUpstreamPolicy` with your service using the `konghq.com/upstream-policy` annotation:

```bash
kubectl annotate -n kong service echo konghq.com/upstream-policy=sticky-session-policy
```

Check that the annotation was applied:

```bash
kubectl get service echo -n kong -o jsonpath='{.metadata.annotations.konghq\.com/upstream-policy}'
```

## Test sticky session behavior

### Initial request

1. Make an initial request to observe the session cookie being set:

    ```bash
    curl -v $PROXY_IP/echo
    ```

1. You should see a `Set-Cookie` header in the response:

    ```bash
    < Set-Cookie: session_id=01234567-89ab-cdef-0123-456789abcdef; Path=/
    ```

1. Note the pod name in the response:

    ```bash
    Running on Pod echo-965f7cf84-frpjc.
    ```

### Repeat requests with the same cookie

Extract the cookie and make multiple requests:

```bash
COOKIE=$(curl -s -D - $PROXY_IP/echo | grep -i 'set-cookie:' | sed 's/.*session_id=\([^;]*\).*/\1/')

for i in {1..5}; do
  curl -s -H "Cookie: session_id=$COOKIE" $PROXY_IP/echo | grep "Running on Pod"
done
```

All requests are routed to the same pod: 

```bash
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
```

### Behavior without cookie

Compare this to requests without the cookie, which should distribute across different pods:

```bash
for i in {1..5}; do
  curl -s $PROXY_IP/echo | grep "Running on Pod"
done
```

```bash
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-5h56p.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-wlvw9.
```

## Conclusion

Sticky sessions provide a powerful mechanism for maintaining session affinity in Kubernetes environments. By using `KongUpstreamPolicy` with the `sticky-sessions` algorithm, you can ensure that client requests are consistently routed to the same backend pod, improving application performance and user experience.

- Test thoroughly with your specific application requirements
- Consider the trade-offs between session affinity and load distribution
- Combine with health checks for robust traffic management

For more advanced load balancing scenarios, refer to the [load balancing documentation](/gateway/load-balancing/) and explore other algorithms like [Consistent-hashing](/gateway/entities/upstream/#consistent-hashing) and [Least-connections](/gateway/entities/upstream/#least-connections).
