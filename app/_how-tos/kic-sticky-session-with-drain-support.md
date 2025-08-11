---
title: Configure sticky sessions with drain support
description: |
  Learn how to implement sticky sessions with graceful draining of terminating pods using {{site.kic_product_name}}.
  
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Guides

permalink: /kubernetes-ingress-controller/sticky-sessions-with-drain-support/

content_type: how_to

products:
  - kic

works_on:
  - on-prem
  - konnect

tldr:
  q: How do I enable sticky sessions with drain support in {{ site.kic_product_name }}?  
  a: Deploy {{ site.kic_product_name }} using the `--enable-drain-support=true` flag. Next, configure `spec.stickySessions` and set `spec.algorithm` to `sticky-sessions` in a `KongUpstreamPolicy` resource. Finally, attach the `KongUpstreamPolicy` resource to a Kubernetes Service with the `konghq.com/upstream-policy` annotation.

prereqs:
  kubernetes:
    gateway_api: true
    drain_support: true
  entities:
    services:
      - httpbin-service
    routes:
      - httpbin

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg

min_version:
  kic: "3.5"

related_resources:
  - text: "Sticky sessions in {{ site.kic_product_name }}"
    url: /kubernetes-ingress-controller/sticky-sessions/
---

## Deploy additional httpbin replicas

To demonstrate Kong's sticky session functionality we need multiple `httpbin` Pods. Scale out the `httpbin` deployment.

```bash
kubectl scale -n kong --replicas 3 deployment httpbin
```

## Configure sticky sessions with KongUpstreamPolicy

To implement sticky sessions, you'll need to create a `KongUpstreamPolicy` resource that specifies the `sticky-sessions` algorithm and configure your Service to use it.

1. Create a `KongUpstreamPolicy` with sticky sessions:

   ```bash
   echo '
   apiVersion: configuration.konghq.com/v1beta1
   kind: KongUpstreamPolicy
   metadata:
     name: sticky-session-policy
   spec:
     algorithm: sticky-sessions
     hashOn:
       input: "none"
     stickySessions:
       cookie: "session-id"
       cookiePath: "/"
     ' | kubectl apply -f -
   ```

1. Annotate your service to use this policy:

   ```bash
   echo '
   apiVersion: v1
   kind: Service
   metadata:
     name: httpbin
     annotations:
       konghq.com/upstream-policy: sticky-session-policy
     labels:
       app: httpbin
   spec:
     ports:
     - name: http
       port: 80
       targetPort: 80
     selector:
       app: httpbin
     ' | kubectl apply -f -
   ```

## Test sticky sessions

To test if sticky sessions are working, make a request to your service and inspect the response headers for the `session-id` cookie:
{% validation request-check %}
url: /httpbin/anything
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
display_headers: true
{% endvalidation %}

Make additional requests and verify they're being routed to the same pod.

## Test drain support

Scale down your deployment: 
```bash
kubectl scale deployment httpbin --replicas=2
```

Send another request:
{% validation request-check %}
url: /httpbin/anything
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
display_headers: true
{% endvalidation %}

If you have an active session with a pod that's terminating, your session should continue to work. New sessions should be directed only to the remaining healthy pods