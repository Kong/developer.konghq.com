---
title: "{{site.mesh_product_name}}: Observability/tracing troubleshooting steps"
content_type: support
description: General troubleshooting steps for diagnosing why {{site.mesh_product_name}} Observability/tracing isn't collecting the expected data, using the `kuma-demo` app and Envoy config dumps.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What are common pitfalls when troubleshooting {{site.mesh_product_name}} Observability/tracing, and how do I diagnose them?
  a: |
    If tracing isn't collecting the expected data, gather the Envoy config dump, {{site.mesh_product_name}} debug logs, the Mesh resource, and the TrafficTrace (or MeshTrace) policy, then verify the tracing backend and policy are configured correctly and check the logs for errors.
    In the config dump, confirm the expected listeners are present — if the protocol isn't explicitly configured per service (HTTP, HTTP2, or gRPC), jaeger will only show up under `config.bootstrap.cluster.name` and not as a listener.
related_resources:
  - text: kuma-demo app deployment manifest
    url: https://raw.githubusercontent.com/Kong/kuma-demo/master/kubernetes/kuma-demo-aio.yaml
  - text: Kuma observability guide
    url: https://kuma.io/docs/latest/explore/observability/
  - text: Kuma TrafficTrace policy - Zipkin backend configuration
    url: https://kuma.io/docs/latest/policies/traffic-trace/#zipkin
  - text: Kuma TrafficTrace policy - adding a TrafficTrace resource
    url: https://kuma.io/docs/latest/policies/traffic-trace/#add-traffictrace-resource
---

## Problem

When deploying Observability on {{site.mesh_product_name}} you may run into a situation where tracing is not gathering data as you expected. What are some common pitfalls and ways to troubleshoot this further?

## Solution

Note: `TrafficTrace`, referenced below, is deprecated in favor of `MeshTrace`. For new setups, use `MeshTrace` instead. The troubleshooting technique described here remains valid for either policy.

Prerequisites:

We will be referencing the `kuma-demo` app.

We will also assume you've followed this guide.

Files to gather:

1. Config Dump from envoy sidecar for app that is communicating with Jaeger (in the demo app we can use the frontend):

   ```bash
   kubectl port-forward svc/frontend > -n kuma-demo 9901:9901 2>1 &
   ```

   Access the UI through localhost:9901 and gather the `config_dump`.

2. {{site.mesh_product_name}} debug logs

3. Mesh deployment file

   ```bash
   k get mesh <mesh name> -o yaml > meshdata.yaml
   ```

4. Traffic Trace Policy

   ```bash
   k get traffictrace -o yaml > TTData.yaml
   ```

Troubleshooting steps:

1. Verify Tracing backend is configured correctly
2. Verify Traffic Trace policy is configured correctly
3. Verify any errors in the logs.

Debugging the config dump can be intimidating as there is a lot of different data to review. One key thing to look for would be to verify if the expected Listeners are deployed.

Example:

Tracing is only supported over HTTP, HTTP2, gRPC protocols. So you must explicitly specify the protocol for each service.

If the protocol is not configured, then the config dump will only reference jaeger under `config.bootstrap.cluster.name`.

```

      "name": "tracing:jaeger-collector"
```

In a working scenario, jaeger would be referenced as listeners as well.
