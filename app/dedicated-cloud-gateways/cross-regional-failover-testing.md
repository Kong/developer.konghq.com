---
title: "Testing regional failover"
content_type: reference
layout: reference
description: "Use a controlled outage simulation to confirm that your multi-region Dedicated Cloud Gateway deployment automatically fails over to a healthy region."

products:
    - gateway

breadcrumbs:
  - /dedicated-cloud-gateways/

works_on:
  - konnect

tags:
  - dedicated-cloud-gateways
  - failover

related_resources:
  - text: Dedicated Cloud Gateways production readiness guide
    url: /dedicated-cloud-gateways/production-readiness/
  - text: Pre-Function plugin
    url: /plugins/pre-function/
  - text: Dedicated Cloud Gateways reference
    url: /dedicated-cloud-gateways/reference/
  - text: Health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/
---

This page covers how to validate cross-regional failover in a multi-region Dedicated Cloud Gateway deployment. Kong's [Pre-Function plugin](/plugins/pre-function/) simulates a regional outage by forcing health checks to fail, which triggers DNS failover to a secondary region.

The examples here reference AWS Route 53, but the approach works with any DNS-based health check system. Load generation tooling, observability backends, and upstream APIs will differ across environments.

## How it works

The outage is simulated by intercepting health check requests at the gateway. A Pre-Function plugin scoped to the health check route inspects the incoming `Host` header. When the header matches the public edge DNS hostname of the target region, the plugin returns a `400`. The health checker sees the endpoint as unhealthy and DNS shifts traffic to the alternate region.

Disabling the plugin lets health checks pass again. Keep the plugin between test runs — disable it rather than delete it, so you can re-enable it without starting over.

## Prerequisites

You'll need:

- A multi-region data plane deployment with nodes in at least two regions
- A DNS-based health check system like AWS Route 53, with health checks targeting the public edge DNS endpoint of each region
- A dedicated health check route in the control plane, such as `/health`
- Upstream APIs reachable from each region

## Pre-Function plugin configuration

The Pre-Function plugin runs in the `access` phase, scoped to the health check route. It inspects the `Host` header and returns a `400` when the header matches the target region's public edge DNS hostname. All other requests pass through unaffected.

Set `target_host` to the public edge DNS hostname of the region you're testing. In {{site.konnect_short_name}}, this is available under **Connect > Regional Networking > Public Edge DNS** for each region.

```lua
-- Runs in the 'access' phase on the health check route
local host = kong.request.get_host() or ""
local target_host = "YOUR_TARGET_HOST"

if host == target_host then
  kong.log.notice("HostnameFailover: forcing unhealthy for host ", host)
  return kong.response.exit(
    400,
    { message = "region forced unhealthy" },
    { ["Content-Type"] = "application/json" }
  )
end
```

Disable the plugin rather than delete it to restore normal health check behavior. Keeping the configuration means you won't need to set it up again for future test runs.

Here's the full plugin configuration in YAML:

```yaml
config:
  access:
    - |
      local host = kong.request.get_host() or ""
      local target_host = "YOUR_TARGET_HOST"
      if host == target_host then
        kong.log.notice("HostnameFailover: forcing unhealthy for host ", host)
        return kong.response.exit(
          400,
          { message = "region forced unhealthy" },
          { ["Content-Type"] = "application/json" }
        )
      end
  body_filter: []
  header_filter: []
  log: []
  rewrite: []
enabled: false
name: pre-function
```

## Test process

Each run covers two scenarios — failover and recovery — repeated for each region across each transaction set. Use real production APIs rather than mocks; the results will be more meaningful.

Before starting, establish a requests-per-second baseline and let monitoring normalize. Keep observability plugins like OpenTelemetry, Datadog, and HTTP Log running alongside control plane analytics throughout.

Recommended transaction sets:

{% table %}
columns:
  - title: Transaction set
    key: set
  - title: Requests
    key: requests
  - title: Duration
    key: duration
rows:
  - set: Set 1
    requests: "50,000"
    duration: 30 minutes
  - set: Set 2
    requests: "100,000"
    duration: 30 minutes
  - set: Set 3
    requests: "250,000"
    duration: 30 minutes
{% endtable %}

### Failover

Start with load generation at your RPS baseline and let monitoring normalize. Once things are stable, enable the Pre-Function plugin on the health check route. Health check requests will start returning `400`, and the DNS health checker will eventually mark the region as unhealthy — at which point DNS should shift traffic to the alternate region automatically.

Let the test run for the full transaction set duration. Watch for the health check status flipping in your DNS provider and confirm traffic is shifting to the alternate region. Capture observability output and analytics as you go.

How quickly the DNS provider marks the endpoint unhealthy depends on your health check interval and failure threshold settings.

### Recovery

Run the recovery test while the target region is still unhealthy and load generation is active. Disabling the plugin lets health checks pass again, and the DNS provider will start routing traffic back to the recovered region. Traffic should gradually split across both regions as health checks pass.

Use analytics to confirm RPS returns to your baseline. Transition time works the same way as during failover — it depends on your health check interval and threshold settings.

## Test matrix

Run each combination of region and test type once per transaction set. With 2 regions, 2 test types, and 3 transaction sets, that's 12 runs total.

{% table %}
columns:
  - title: Test case
    key: test_case
  - title: Description
    key: description
  - title: Expected result
    key: expected_result
rows:
  - test_case: Region A failover
    description: Region A health check returns `400`. Traffic routes to Region B.
    expected_result: Automatic failover to Region B with acceptable service interruption.
  - test_case: Region B failover
    description: Region B health check returns `400`. Traffic routes to Region A.
    expected_result: Automatic failover to Region A with acceptable service interruption.
  - test_case: Region A recovery
    description: Region A is restored to healthy while load generation is running.
    expected_result: Traffic splits across both regions. RPS returns to baseline.
  - test_case: Region B recovery
    description: Region B is restored to healthy while load generation is running.
    expected_result: Traffic splits across both regions. RPS returns to baseline.
{% endtable %}

## Route 53 health check parameters

Route 53 aggregates responses from its distributed health checkers to determine endpoint health:

- If **more than 18%** of health checkers report an endpoint as healthy, Route 53 considers it **healthy**.
- If **18% or fewer** health checkers report an endpoint as healthy, Route 53 considers it **unhealthy**.

How quickly the transition happens depends on the health check interval and failure threshold you've configured in AWS.
