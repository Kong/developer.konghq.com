---
title: Configure Service health checks
description: |
  How to enable passive and active health checks for upstream services
content_type: how_to

permalink: /kubernetes-ingress-controller/service-health-checks/

breadcrumbs:
  - /kubernetes-ingress-controller/

products:
  - kic

works_on:
  - on-prem
  - konnect

tldr:
  q: How do I enable health checks with {{ site.kic_product_name }}?
  a: Configure `spec.healthchecks` in a `KongUpstreamPolicy` resource, then attach the `KongUpstreamPolicy` resource to a Kubernetes Service using the `konghq.com/upstream-policy` annotation

prereqs:
  kubernetes:
    gateway_api: true
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

next_steps:
  - text: Read more about health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/
---

## Health check types

{{ site.base_gateway }} supports active and passive health checks. This allows {{site.base_gateway}} to automatically short-circuit requests to specific Pods that are misbehaving in your Kubernetes Cluster. The process to re-enable these pods is different between active and passive health checks.

### Passive health checks

Pods that are marked as unhealthy by {{ site.base_gateway }} are **permanently** marked as unhealthy.

If a passive health check for a service that runs in a cluster and if the Pod that runs the service reports an error, {{ site.base_gateway }} returns a 503, indicating that the service is unavailable. {{ site.base_gateway }} doesn't proxy any requests to the unhealthy pod.

There is no way to mark the pod as healthy again using {{ site.kic_product_name }} and passive health checks. To resolve the issue, choose on of the following options:

- **Delete the current Pod:** {{ site.base_gateway }} then sends proxy requests to the new Pod that is in its place.
- **Scale the deployment:** {{ site.base_gateway }} then sends proxy requests to the new Pods and leaves the short-circuited Pod out of the loop.

### Active health checks

Pods that are marked as unhealthy by {{ site.base_gateway }} are **temporarily** marked as unhealthy.

{{ site.base_gateway }} will make a request to the healthcheck path periodically. When it has received enough healthy responses, it will re-enable the Pod in the load balancer and traffic will be routed to the Pod again.

## Enable passive health checking

1.  All health checks are done at the Service-level. To configure {{ site.base_gateway }} to short-circuit requests to a Pod if it throws 3 consecutive errors, add a `KongUpstreamPolicy` resource:

    ```bash
    echo '
    apiVersion: configuration.konghq.com/v1beta1
    kind: KongUpstreamPolicy
    metadata:
        name: demo-health-checking
        namespace: kong
    spec:
      healthchecks:
        passive:
          healthy:
            successes: 3
          unhealthy:
            httpFailures: 3
    ' | kubectl apply -f -
    ```

1. Associate the KongUpstreamPolicy resource with `httpbin` Service:

    ```bash
    kubectl patch -n kong svc httpbin -p '{"metadata":{"annotations":{"konghq.com/upstream-policy":"demo-health-checking"}}}'
    ```

1. Test the Ingress rule by sending two requests to `/status/500` that simulate a failure from the upstream service:

{% validation request-check %}
url: /httpbin/status/500
display_headers: true
count: 2
indent: 4
status_code: 500
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

    The results should look like this:
    ```text
    HTTP/1.1 500 INTERNAL SERVER ERROR
    Content-Type: text/html; charset=utf-8
    Content-Length: 0
    Connection: keep-alive
    Server: gunicorn/19.9.0
    Access-Control-Allow-Origin: *
    Access-Control-Allow-Credentials: true
    X-Kong-Upstream-Latency: 1
    X-Kong-Proxy-Latency: 0
    Via: kong/{{ site.data.gateway_latest.release }}
    ```

1. Send a third request with `status/200`. This will reset the circuit breaker counter as it is a healthy response:

{% validation request-check %}
url: /httpbin/status/200
display_headers: true
indent: 4
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

    The results should look like this:
    ```text
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    Content-Length: 0
    Connection: keep-alive
    Server: gunicorn/19.9.0
    Access-Control-Allow-Origin: *
    Access-Control-Allow-Credentials: true
    X-Kong-Upstream-Latency: 1
    X-Kong-Proxy-Latency: 0
    Via: kong/{{ site.data.gateway_latest.release }}
    ```
    {{site.base_gateway}} didn't short-circuit because there were only two failures.

### Trip the circuit breaker

1. Send three requests to `/status/500` to mark the pod as unhealthy. We need three requests as this is the number provided in `unhealthy.httpFailures` in the `KongUpstreamPolicy` resource:

{% validation request-check %}
url: /httpbin/status/500
display_headers: true
count: 3
indent: 4
status_code: 500
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

    The results should look like this:
    ```text
    HTTP/1.1 500 INTERNAL SERVER ERROR
    Content-Type: text/html; charset=utf-8
    Content-Length: 0
    Connection: keep-alive
    Server: gunicorn/19.9.0
    Access-Control-Allow-Origin: *
    Access-Control-Allow-Credentials: true
    X-Kong-Upstream-Latency: 1
    X-Kong-Proxy-Latency: 0
    Via: kong/{{ site.data.gateway_latest.release }}
    ```

1. Make a request to `/status/200` and note that {{ site.base_gateway }} returns an `HTTP 503`:

{% validation request-check %}
url: /httpbin/status/200
display_headers: true
indent: 4
status_code: 503
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

    The results should look like this:
    ```text
    HTTP/1.1 503 Service Temporarily Unavailable
    Content-Type: application/json; charset=utf-8
    Connection: keep-alive
    Content-Length: 62
    X-Kong-Response-Latency: 0
    Server: kong/{{ site.data.gateway_latest.release }}

    {
      "message":"failure to get a peer from the ring-balancer"
    }%
    ```

    Because there's only one Pod of `httpbin` Service running in the cluster, and that is throwing errors, {{ site.base_gateway }} doesn't proxy any additional requests. To get resolve this, you can use active health-check, where each instance of {{ site.base_gateway }} actively probes Pods to check if they are healthy.

## Enable active health checking

Active health checking can automatically mark an upstream service as healthy again once it receives enough `healthy` responses.

1.  Update the KongUpstreamPolicy resource to use active health checks:

    ```bash
    echo '
    apiVersion: configuration.konghq.com/v1beta1
    kind: KongUpstreamPolicy
    metadata:
        name: demo-health-checking
        namespace: kong
    spec:
      healthchecks:
        active:
          healthy:
            interval: 5
            successes: 3
          httpPath: /status/200
          type: http
          unhealthy:
            httpFailures: 1
            interval: 5
        passive:
          healthy:
            successes: 3
          unhealthy:
            httpFailures: 3
    ' | kubectl apply -f -
    ```

    This configures {{site.base_gateway}} to actively probe `/status/200` every five seconds. If a Pod is unhealthy from {{ site.base_gateway }}'s perspective, three successful probes change the status of the Pod to healthy, and {{site.base_gateway}} again starts to forward requests to that Pod. Wait 15 seconds for the pod to be marked as healthy before continuing.

1. Make a request to `/status/200` after 15 seconds:

{% validation request-check %}
sleep: 15
url: /httpbin/status/200
display_headers: true
indent: 4
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

    The results should look like this:
    ```text
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    Content-Length: 0
    Connection: keep-alive
    Server: gunicorn/19.9.0
    Access-Control-Allow-Origin: *
    Access-Control-Allow-Credentials: true
    X-Kong-Upstream-Latency: 1
    X-Kong-Proxy-Latency: 1
    Via: kong/{{ site.data.gateway_latest.release }}
    ```

1.  Trip the circuit again by sending three requests that return the `HTTP 500` from httpbin:

{% validation request-check %}
url: /httpbin/status/500
display_headers: true
count: 3
indent: 4
status_code: 500
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

    The httpbin pod is now marked as unhealthy for 15 seconds. This is the duration required for active health checks to re-classify the httpbin Pod as healthy again (three requests with a five second interval).

    ```bash
    curl -i $PROXY_IP/httpbin/status/200
    ```

    The results should look like this:

    ```text
    HTTP/1.1 503 Service Temporarily Unavailable
    Content-Type: application/json; charset=utf-8
    Connection: keep-alive
    Content-Length: 62
    X-Kong-Response-Latency: 0
    Server: kong/{{ site.data.gateway_latest.release }}

    {
      "message":"failure to get a peer from the ring-balancer"
    }%
    ```

1.  Wait 15 seconds then make another request:

{% validation request-check %}
sleep: 15
url: /httpbin/status/200
display_headers: true
indent: 4
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

    The results should look like this:
    ```text
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    Content-Length: 0
    Connection: keep-alive
    Server: gunicorn/19.9.0
    Access-Control-Allow-Origin: *
    Access-Control-Allow-Credentials: true
    X-Kong-Upstream-Latency: 1
    X-Kong-Proxy-Latency: 1
    Via: kong/{{ site.data.gateway_latest.release }}
    ```

Active health checking has marked the upstream healthy again in {{ site.base_gateway }}
