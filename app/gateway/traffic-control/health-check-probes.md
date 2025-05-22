---
title: Health check probes
content_type: reference
layout: reference
description: 'Use health check probes to monitor {{site.base_gateaway}} availability.'
products:
  - gateway
breadcrumbs:
  - /gateway/traffic-control-and-routing/
works_on:
  - on-prem
  - konnect
tags:
  - status
  - monitoring
faqs:
  - q: What happens if a node is not ready?
    a: |
      The `/status/ready` endpoint returns a `503 Service Temporarily Unavailable` response with a `message` field explaining the failure. 
      This is useful for debugging and monitoring readiness status in real time.
  - q: What limitations do health check probes have?
    a: |
      The health check endpoints do **not** detect:
      * System performance issues
      * DNS, cloud, or networking failures
      * Errors from third-party plugins
      * Upstream service availability
related_resources:
  - text: "Health checks and circuit breakers"
    url: /gateway/traffic-control/health-checks-circuit-breakers/
  - text: "Hybrid Mode"
    url: /gateway/hybrid-mode/
  - text: Load balancing in {{site.base_gateway}}
    url: /gateway/load-balancing/
  - text: Traffic control and routing
    url: /gateway/traffic-control-and-routing/
---

The readiness check endpoint has two states: 

* `200 OK`: when {{site.base_gateway}} is ready.
* `503 Service Temporarily Unavailable`: when {{site.base_gateway}} is not ready. 

The readiness endpoint does not return detailed information about the node status, but it is still useful for load balancers and other tools that need to monitor the readiness of {{site.base_gateway}} instances.

## Enable the node readiness endpoint

To use the [`/status/ready`](/api/gateway/admin-ee/#/operations/get-status) endpoint, enable the status API server in `kong.conf`, and specify the port you want to use. Readiness probes should be enabled on all nodes, including standalone, Control Plane, and Data Plane nodes.

```conf
status_listen = 0.0.0.0:8100
```

{:.info}
> For information on configuring `kong.conf` review the [Managing {{site.base_gateway}} configuration](/gateway/manage-kong-conf/) documentation

## Types of health checks

For each {{site.base_gateway}} node, there are two types of health checks:

* **Liveness**: The `/status` endpoint responds with a `200 OK` status if {{site.base_gateway}} is running. Use:

  ```sh
  curl -i http://localhost:8100/status
  ```

* **Readiness**: The `/status/ready` endpoint responds with `200 OK` if {{site.base_gateway}} has a valid config and is ready to serve. Use:

  ```sh
  curl -i http://localhost:8100/status/ready
  ```

These endpoints follow the [Kubernetes health check probe patterns](/kubernetes-ingress-controller/service-health-checks/).
Liveness may return `200 OK` before readiness. Only use readiness probes to determine if a node is ready to receive traffic.

## Readiness by node type

Readiness varies by deployment type. A `200 OK` can mean something different depending on the {{site.base_gateaway}} configuration. 


{% navtabs "behaviour" %}
{% navtab "Traditional mode" %}

In [traditional mode](/gateway/traditional-mode/), readiness returns `200 OK` when:

1. The database is connected
2. Workers are ready
3. All plugins are initialized

{% endnavtab %}
{% navtab "Hybrid mode" %}

In [hybrid mode](/gateway/hybrid-mode/) (`data_plane`) or [DB-less mode](/gateway/db-less-mode/), readiness returns `200 OK` when:

1. A valid, non-empty config is loaded
2. Workers are ready
3. All plugins are initialized

{% endnavtab %}
{% navtab "Hybrid mode (control plane role)" %}

In hybrid mode (`control_plane`), readiness returns `200 OK` when:

1. The database is connected

{% endnavtab %}
{% endnavtabs %}



## Kubernetes configuration

Update `readinessProbe` in your deployment:

```yaml
readinessProbe:
  httpGet:
    path: /status/ready
    port: 8100
  initialDelaySeconds: 10
  periodSeconds: 5
```

