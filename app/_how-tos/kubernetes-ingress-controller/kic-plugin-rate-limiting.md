---
title: "Rate limiting with {{ site.kic_product_name }}"
short_title: Rate limiting
description: |
  Configure Rate Limiting using a `local` or `redis` policy
content_type: how_to

permalink: /kubernetes-ingress-controller/rate-limiting/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: How To

tags:
  - rate-limiting

plugins:
  - rate-limiting

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I add rate limiting to a Service with {{ site.kic_product_name }}?
  a: Create a `rate-limiting` `KongPlugin` instance and annotate your Service with the `konghq.com/plugins` annotation.

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
---

## Create a Rate Limiting Plugin

To add rate limiting to the `echo` Service, create a new [Rate Limiting](/plugins/rate-limiting/) `KongPlugin`:

{% entity_example %}
type: plugin
data:
  name: rate-limit-5-min
  plugin: rate-limiting
  config:
    minute: 5
    policy: local

  service: echo
{% endentity_example %}

## Validate your configuration

Send repeated requests to decrement the remaining limit headers, and block requests after the fifth request:

{% validation rate-limit-check %}
iterations: 6
url: '/echo'
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
message: null
output:
  explanation: |
    The `RateLimit-Remaining` header indicates how many requests are remaining before the rate limit is enforced.  The first five responses return `HTTP/1.1 200 OK` which indicates that the request is allowed. The final request returns `HTTP/1.1 429 Too Many Requests` and the request is blocked.

    If you receive an `HTTP 429` from the first request, wait 60 seconds for the rate limit timer to reset.
{% endvalidation %}

## Scale to multiple pods

The `policy: local` setting in the plugin configuration tracks request counters in each Pod’s local memory separately. Counters are not synchronized across Pods, so clients can send requests past the limit without being throttled if they route through different Pods.

To test this, scale your Deployment to three replicas:

```bash
kubectl scale --replicas 3 -n kong deployment kong-gateway
```

{:.warning}
> It may take up to 30 seconds for the new replicas to come online. Run `kubectl get pods -n kong` and check the `Ready` column to validate that the replicas are online

Sending requests to this Service does not reliably decrement the remaining counter:

{% validation rate-limit-check %}
iterations: 10
url: '/echo'
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
grep: "(< RateLimit-Remaining)"
message: null
output:
  explanation: |
    The requests are distributed across multiple Pods, each with their own in memory rate limiting counter:
  expected:
    - value:
      - "< RateLimit-Remaining: 4"
    - value:
      - "< RateLimit-Remaining: 4"
    - value:
      - "< RateLimit-Remaining: 3"
    - value:
      - "< RateLimit-Remaining: 4"
    - value:
      - "< RateLimit-Remaining: 3"
    - value:
      - "< RateLimit-Remaining: 2"
    - value:
      - "< RateLimit-Remaining: 3"
    - value:
      - "< RateLimit-Remaining: 2"
    - value:
      - "< RateLimit-Remaining: 1"
    - value:
      - "< RateLimit-Remaining: 1"
{% endvalidation %}

Using a load balancer that distributes client requests to the same Pod can alleviate this somewhat, but changes to the number of replicas can still disrupt accurate accounting. To consistently enforce the limit, the plugin needs to use a shared set of counters across all Pods. The `redis` policy can do this when a Redis instance is available.

## Deploy Redis to your Kubernetes cluster

Redis provides an external database for {{site.base_gateway}} components to store shared data, such as rate limiting counters. There are several options to install it.

Bitnami provides a [Helm chart](https://github.com/bitnami/charts/tree/main/bitnami/redis) for Redis with turnkey options for authentication.

1.  Create a password Secret and replace `PASSWORD` with a password of your choice.

    ```bash
    kubectl create -n kong secret generic redis-password-secret --from-literal=redis-password=PASSWORD
    ```

1. Install Redis

    ```bash
    helm install -n kong redis oci://registry-1.docker.io/bitnamicharts/redis \
      --set auth.existingSecret=redis-password-secret \
      --set architecture=standalone
    ```

    Helm displays the instructions that describes the new installation.

    {:.warning}
    > If Redis is not accessible, {{ site.base_gateway }} will allow incoming requests. Run `kubectl get pods -n kong redis-master-0` and check the `Ready` column to ensure that Redis is ready before continuing.

1. Update your plugin configuration with the `redis` policy, Service, and credentials. Replace `PASSWORD` with the password that you set for Redis.

    ```bash
    kubectl patch -n kong kongplugin rate-limit-5-min --type json --patch '[
      {
        "op":"replace",
        "path":"/config/policy",
        "value":"redis"
      },
      {
        "op":"add",
        "path":"/config/redis_host",
        "value":"redis-master"
      },
      {
        "op":"add",
        "path":"/config/redis_password",
        "value":"PASSWORD"
      }
    ]'
    ```

    If the `redis_username` is not set, it uses the default `redis` user.

## Test rate limiting in a multi-node deployment

Send the following request to test the rate limiting functionality in the multi-Pod deployment:
{% validation rate-limit-check %}
iterations: 6
url: '/echo'
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
grep: "(< RateLimit-Remaining|< HTTP)"
message: null
output:
  explanation: |
    The counters decrement sequentially regardless of the {{site.base_gateway}} replica count.
  expected:
    - value:
      - "< HTTP/1.1 200 OK"
      - "< RateLimit-Remaining: 4"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< RateLimit-Remaining: 3"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< RateLimit-Remaining: 2"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< RateLimit-Remaining: 1"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< RateLimit-Remaining: 0"
    - value:
      - "< HTTP/1.1 429 Too Many Requests"
      - "< RateLimit-Remaining: 0"
{% endvalidation %}