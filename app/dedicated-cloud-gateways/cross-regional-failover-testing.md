---
title: "Cross-regional failover testing for Dedicated Cloud Gateways"
content_type: reference
layout: reference
description: "A reference runbook for validating cross-regional failover in a multi-region Dedicated Cloud Gateway deployment using a controlled outage simulation."

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

This document describes a general approach for validating cross-regional failover in a multi-region Dedicated Cloud Gateway deployment. The core mechanism uses Kong's [Pre-Function plugin](/plugins/pre-function/) to simulate a regional outage, triggering DNS-based failover to a secondary region.

While the examples here reference AWS Route 53, the approach can be adapted to any DNS-based health check and failover system. The specifics of load generation tooling, observability backends, and upstream APIs will vary by environment.

## How it works

The simulated outage works by intercepting health check requests at the gateway level. A Pre-Function plugin scoped to the health check route inspects the incoming `Host` header. When the header matches the public edge DNS hostname of the target region, the plugin returns a `400` response. From the perspective of the health checker, the endpoint appears unhealthy and DNS resolution shifts to the alternate region.

Disabling the plugin restores the region to a healthy state. The plugin should be retained between test runs rather than deleted, so it can be re-enabled without reconfiguration.

## Prerequisites

This approach requires the following to be in place before testing begins:

- A multi-region data plane deployment with nodes in at least two regions
- A DNS-based health check system (such as AWS Route 53) with health checks targeting the public edge DNS endpoint of each region
- A dedicated health check route in the control plane (for example, `/health`)
- A representative set of upstream APIs reachable from each region — real production APIs are preferred over mocks for meaningful results
- Observability instrumentation in place (for example, OpenTelemetry, Datadog, HTTP Log plugin) to capture traffic behavior during the test
- A pre-established RPS (requests per second) baseline to compare against during and after the test
- Access to control plane analytics to monitor traffic distribution

Recommended transaction sets for load generation:

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

## Pre-Function plugin configuration

The Pre-Function plugin runs in the `access` phase and is scoped to the health check route. It inspects the `Host` header of incoming requests and returns a `400` when the header matches the target region's public edge DNS hostname. All other requests pass through unaffected.

The `target_host` variable must be set to the public edge DNS hostname of the region under test. In {{site.konnect_short_name}}, this hostname is available under **Connect > Regional Networking > Public Edge DNS** for each region.

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

The plugin should be **disabled** (not deleted) to restore normal health check behavior. Retaining the plugin configuration avoids reconfiguration between test runs.

The following is a full plugin configuration in YAML format for reference:

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

Each test run covers two scenarios: a failover test and a recovery test. Both should be run for each region across each transaction set.

### Failover

A failover test begins with load generation running at the established RPS baseline, with monitoring allowed to normalize before the simulated outage is introduced. Enabling the Pre-Function plugin on the health check route causes the DNS health checker to begin receiving `400` responses, eventually marking the region as unhealthy. At that point, DNS should shift traffic to the alternate region automatically.

The test continues for the full duration of the transaction set, with observability output and analytics captured throughout. The key signals to monitor are the health check status transition in the DNS provider and the change in traffic distribution across regions.

The time between enabling the plugin and the DNS provider marking the endpoint unhealthy depends on the configured health check interval and failure threshold.

### Recovery

A recovery test starts with the target region already in an unhealthy state and load generation still running. Disabling the Pre-Function plugin restores healthy responses on the health check route. The DNS provider should begin routing traffic back to the recovered region, and traffic should gradually split across both regions as health checks pass.

Analytics can be used to confirm that RPS returns to the pre-test baseline within acceptable performance parameters. As with failover, the transition time depends on the health check interval and threshold settings.

## Test matrix

Each combination of region and test type should be run once per transaction set. Recommended coverage: 2 regions × 2 test types × 3 transaction sets = 12 total runs.

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

Route 53 aggregates responses from its globally distributed health checkers and applies the following threshold when determining endpoint health:

- If **more than 18%** of health checkers report an endpoint as healthy, Route 53 considers it **healthy**.
- If **18% or fewer** health checkers report an endpoint as healthy, Route 53 considers it **unhealthy**.

The speed of transition depends on the health check interval and failure threshold configured in the AWS Console.
