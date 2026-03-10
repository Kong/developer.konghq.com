---
title: "Testing regional failover"
content_type: reference
layout: reference
description: "Use a controlled outage simulation to confirm that your multi-region {{site.konnect_short_name}} data plane deployment automatically fails over to a healthy region."

products:
    - gateway

breadcrumbs:
  - /gateway/

works_on:
  - konnect

tags:
  - failover

related_resources:
  - text: Pre-Function plugin
    url: /plugins/pre-function/
  - text: Health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/
---

Testing cross-regional failover ensures that if one region goes down, due to an outage, a zone failure, or a cloud provider incident, traffic can automatically or manually shift to a healthy region. 
To test this, you can use the [Pre-Function plugin](/plugins/pre-function/) to simulate a regional outage by forcing health checks to fail, which triggers DNS failover to a secondary region.

The examples here reference AWS Route 53, but the approach works with any DNS-based health check system. Load generation tooling, observability backends, and upstream APIs will differ across environments.

## How it works

In this guide, the outage is simulated by intercepting health check requests at the gateway. 
A Pre-Function plugin scoped to the health check route inspects the incoming `Host` header. 
When the header matches the public edge DNS hostname of the target region, the plugin returns a `400`. 
The health checker sees the endpoint as unhealthy and the DNS shifts traffic to the alternate region.

After you simulate an outage, you disable the Pre-Function plugin to test recovery by allowing health checks to pass again. 
Do not delete the plugin between test runs, disable instead so you can re-enable it for subsequent tests without having to start over.

## Route 53 health check parameters

Route 53 aggregates responses from its distributed health checkers to determine endpoint health:

- If **more than 18%** of health checkers report an endpoint as healthy, Route 53 considers it **healthy**.
- If **18% or fewer** health checkers report an endpoint as healthy, Route 53 considers it **unhealthy**.

How quickly the transition happens depends on the health check interval and failure threshold you've configured in AWS.

## Prerequisites

You'll need:

- A multi-region data plane deployment with nodes in at least two regions
- A DNS-based health check system like [AWS Route 53](https://aws.amazon.com/route53/), with health checks targeting the public edge DNS endpoint of each region
- A dedicated health check route in the control plane, such as `/health`
- Upstream APIs reachable from each region

## Pre-Function plugin configuration

To use the Pre-Function plugin to test regional failover, you'll configure it to run in the `access` phase and scope it to the health check Route. 
The plugin inspects the `Host` header and returns a `400` when the header matches the target region's public edge DNS hostname. 
All other requests pass through unaffected.

Set `target_host` to the public edge DNS hostname of the region you're testing.

<!--vale off-->
{% entity_example %}
type: plugin
data:
  name: pre-function-healthcheck-failover
  plugin: pre-function
  route: $HEALTH_CHECK_ROUTE
  config:
    access:
      - |
        local host = kong.request.get_host() or ""
        local target_host = "$YOUR_TARGET_HOST"
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
{% endentity_example %}
<!--vale on-->

## Test process

Each run covers two scenarios, failover and recovery, repeated for each region across each transaction set. 
Use real production APIs rather than mocks, the results will be more meaningful.

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


For example, a transaction set would look like the following for set 1 for the US region:
1. Start sending requests at your 50,000 baseline. Let things normalize.
1. Enable the Pre-Function plugin. The US region starts returning `400` and Route 53 marks it as unhealthy. Traffic shifts to EU.
1. Keep the load running. Disable the plugin, which will cause US health checks to pass again. Route 53 gradually routes traffic back and RPS returns to baseline across both regions.

### Failover

Start with load generation at your RPS baseline and let monitoring normalize. 
After things are stable, enable the Pre-Function plugin on the health check route. 
Health check requests will start returning `400`, and the DNS health checker will eventually mark the region as unhealthy. 
DNS should shift traffic to the alternate region automatically.

Let the test run for the full transaction set duration. 
Watch for the health check status to change in your DNS provider and confirm traffic is shifting to the alternate region. 
Capture observability output and analytics as you go.

How quickly the DNS provider marks the endpoint unhealthy depends on your health check interval and failure threshold settings.

### Recovery

Test recovery while the target region is still unhealthy and load generation is active. 
Disable the plugin to let health checks pass again, and the DNS provider will start routing traffic back to the recovered region. 
Traffic should gradually split across both regions as health checks pass.

Use analytics to confirm RPS returns to your baseline. Transition time works the same way as during failover— it depends on your health check interval and threshold settings.

## Test matrix

Run each combination of region and test type once per transaction set. With two regions, two test types, and three transaction sets, that's 12 runs total.

<!--vale off-->
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
<!--vale on-->


