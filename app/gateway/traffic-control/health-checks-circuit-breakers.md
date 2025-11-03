---
title: Health checks and circuit breakers
content_type: reference
layout: reference

products:
  - gateway

works_on:
  - on-prem
  - konnect
search_aliases:
  - circuit breakers
breadcrumbs:
  - /gateway/traffic-control-and-routing/

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

related_resources:
- text: Upstream entity
  url: /gateway/entities/upstream/
- text: Target entity
  url: /gateway/entities/target/
- text: Load balancing in {{site.base_gateway}}
  url: /gateway/load-balancing/
- text: Traffic control and routing
  url: /gateway/traffic-control-and-routing/
- text: Health check probes
  url: /gateway/traffic-control/health-checks-probes/

description: |
  {{site.base_gateway}} supports two kinds of health checks, which can be used separately or in conjunction: active and passive (also known as circuit breakers).

faqs:
  - q: Why should I choose active or passive health checks?
    a: |
      * Active health checks can automatically re-enable a Target in the
      ring balancer as soon as it becomes healthy again. Passive health checks can't.
      * Passive health checks don't produce additional traffic to the
      Target. Active health checks do.
      * An active health checker requires a known URL with a reliable status response
      in the Target to be configured as a probe endpoint (which may be as
      simple as `"/"`). Passive health checks don't need this configuration.
      * By providing a custom probe endpoint for an active health checker,
      an application can determine its own health metrics and produce a status
      code to be consumed by {{site.base_gateway}}. 
      Even though a Target continues to serve traffic which looks healthy to the passive health checker, it would be able to respond to the active probe with a failure status, essentially requesting to be relieved from taking new traffic.

  - q: Do health checks affect all nodes in the cluster?
    a: |
      The objective of a health check is to dynamically mark Targets as healthy or unhealthy for a given {{site.base_gateway}} node. There is no cluster-wide synchronization of health information, so each {{site.base_gateway}} node determines the health of its Targets separately. 

      This is useful because while one {{site.base_gateway}} node may be able to connect to a Target successfully, another node could fail to reach the same Target.
      The first node would consider the Target healthy, while the second would mark it as unhealthy and start routing traffic to other Targets of the Upstream.

tags:
    - load-balancing

---

Using a combination of [Targets](/gateway/entities/target/) and [Upstreams](/gateway/entities/upstream/), you can proxy requests to an upstream service through a ring balancer. 
The ring balancer is a {{site.base_gateway}} load balancer that distributes the traffic load among Targets, and manages active Targets based on their health.

An Upstream entity typically points to one or more Target entities, and each Target points to a different IP address (or hostname) and port. 
Based on the Upstream configuration, the ring balancer performs health checks on the Targets, marking Targets healthy or unhealthy based on whether they are responsive or not. 
The ring balancer then routes traffic only to healthy Targets.

{{site.base_gateway}} supports two types of health checks:

* [**Active checks**](#active-health-checks): {{site.base_gateway}} periodically requests a specific HTTP or HTTPS endpoint in the Target and determines the health of the Target based on its response.
Active health checks are dynamic and can disable and re-enable Targets based on their health.

* [**Passive checks**](#passive-health-checks-circuit-breakers) (also known as **circuit breakers**): {{site.base_gateway}} analyzes the ongoing traffic being proxied and determines the health of Targets based on their behavior.
Passive health checks can only disable unhealthy Targets, they never re-enable Targets automatically.
  
{:.info}
> **Note:** Passive health checks are not available in {{site.konnect_short_name}} or hybrid mode.

You can also combine the two modes. 
For example, you could enable passive health checks to monitor Target health based solely on its traffic, then use active health checks while the Target is unhealthy to re-enable it automatically.

Health checks are disabled by default.

## How does a health check determine health?

### Determining health for Targets

Any request to a Target can produce a TCP error, timeout, or an HTTP status code. 
The health check uses the data in the request to determine whether a Target is healthy or unhealthy.
* For active checks, this information is gathered by an active probe
* For passive checks, this information is gathered from a proxied request

Based on the gathered data, the health checker updates a series of internal counters:

* If the returned status code is configured as `healthy`, it
increments the `Successes` counter for the Target and clears all its other
counters
* If it fails to connect, it increments the `TCP failures` counter
for the Target and clears the `Successes` counter
* If it times out, it increments the `Timeouts` counter
for the Target and clears the `Successes` counter
* If the returned status code is one configured as `unhealthy`, it
increments the `HTTP failures` counter for the Target and clears the `Successes` counter

If any of the `TCP failures`, `HTTP failures`, or `timeouts` counters reach
their configured threshold, the Target will be marked as unhealthy.

If the `Successes` counter reaches its configured threshold, the Target will be
marked as healthy.

The list of which HTTP status codes are `healthy` or `unhealthy` and the
individual thresholds for each of these counters are configurable for each individual Upstream.
You can find all of the default values for an Upstream in the [Upstream schema](/gateway/entities/upstream/#schema).

{:.info}
> **Notes**:
> * Unhealthy Targets won't be removed from the [load balancer](/gateway/entities/upstream/#load-balancing-algorithms), and won't have any impact on the balancer layout when using a hashing algorithm. Instead, they will just be skipped.
> * Health checks operate only on [*enabled* Targets](/gateway/entities/target/) and don't modify the status of a Target in the {{site.base_gateway}} database.
> * The [DNS caveats](/gateway/traffic-control/load-balancing-reference/#dns-load-balancing-caveats) also apply to health checks. 
> If using hostnames for the Targets, then make sure the DNS server always returns the full set of IP addresses for a name, and does not limit the response. 

### Determining health for Upstreams

The health of an Upstream is determined based on the status of its Targets. 
You can configure the threshold for a healthy Upstream using its [`healthchecks.threshold`](/gateway/entities/upstream/#schema) parameter.
This sets a percentage of minimum available Target `weight` (capacity) for the Upstream to be considered healthy.

If the available capacity percentage of an Upstream is less than the configured threshold, the Upstream is considered unhealthy and {{site.base_gateway}} will respond to requests to the Upstream with `503 Service Unavailable`.

Here is a simple example:

* You have an Upstream configured with `healthchecks.threshold=55`
* The Upstream has 5 Targets, each with `weight=100`, so the total weight in the ring balancer is 500
* Each Target represents 20% of the total available capacity

In this scenario, the Upstream can handle losing 2 of its 5 Targets, as it will then be working at 60% capacity, which is still higher than the configured threshold of 55%. 
Once a third Target becomes unhealthy, the capacity drops to 40%, and the Upstream itself becomes unhealthy as well. 

Once it enters an unhealthy state, the Upstream will only return errors. 
This lets the Targets recover from the cascading failures they were experiencing.

When the Targets start recovering and the Upstream's available capacity passes the threshold again, the health status of the ring balancer is automatically updated and the Upstream is reactivated.

## Active health checks

Active health checks actively probe Targets for their health. 
When active health checks are enabled in an Upstream entity, {{site.base_gateway}} periodically issues HTTP or HTTPS requests to a configured path at each Target of the Upstream. 
This allows {{site.base_gateway}} to automatically enable and disable Targets in the balancer based on the probe results.

The interval between active health checks can be configured separately for healthy or unhealthy Targets. 

{:.info}
> **Note:** Active health checks only support HTTP/HTTPS Targets. They
don't apply to Upstreams assigned to Services with the protocol attribute set to `tcp` or `tls`.

### Configure active health checks

To enable active health checks, you need to configure the parameters
under `healthchecks.active` in the [Upstream object configuration](/gateway/entities/upstream/#schema).

{% entity_params_table %}
entity: Upstream
config:
  - name: healthchecks.active.type
    description: Specify whether to perform `http` or `https` probes, or set this field to `tcp` to test the connection to a given host and port.
  - name: healthchecks.active.healthy.interval
    description: Interval between active health checks for healthy Targets (in seconds). Set this to a positive value to enable active healthchecks for healthy Targets.
  - name: healthchecks.active.unhealthy.interval
    description: Interval between active health checks for unhealthy Targets (in seconds). Set this to a positive value to enable active healthchecks for unhealthy Targets.
  - name: healthchecks.active.http_path
    description: The path that should be used when issuing the HTTP GET request to the Target. The default value is `"/"`.
  - name: healthchecks.active.timeout
    description: The connection timeout limit for the HTTP GET request of the probe. The default value is 1 second.
  - name: healthchecks.active.concurrency
    description: Number of Targets to check concurrently in active health checks.
  - name: healthchecks.active.https_verify_certificate
    description: (*Only used for HTTPS*) Whether to check the validity of the SSL certificate of the remote host when performing active health checks using HTTPS. <br><br> Failed TLS verifications will increment the `TCP failures` counter. `HTTP failures` refer only to HTTP status codes, whether probes are done through HTTP or HTTPS.
  - name: healthchecks.active.https_sni
    description: (*Only used for HTTPS*) The hostname to use as an SNI (Server Name Identification) when performing active health checks using HTTPS. This is particularly useful when Targets are configured using IPs, so that the Target host's certificate can be verified with the proper SNI.
  - name: healthchecks.active.healthy.successes
    description: Number of successes in active probes (as defined by `healthchecks.active.healthy.http_statuses`) to consider a Target healthy.
  - name: healthchecks.active.unhealthy.tcp_failures
    description: Number of TCP failures or TLS verification failures in active probes to consider a Target unhealthy.
  - name: healthchecks.active.unhealthy.timeouts
    description: Number of timeouts in active probes to consider a Target unhealthy.
  - name: healthchecks.active.unhealthy.http_failures
    description: Number of HTTP failures in active probes (as defined by `healthchecks.active.unhealthy.http_statuses`) to consider a Target unhealthy.
  - name: healthchecks.active.healthy.http_statuses
    description: An array of HTTP statuses to consider a success, indicating healthiness, when returned by a probe in active health checks.
  - name: healthchecks.active.unhealthy.http_statuses
    description: An array of HTTP statuses to consider a failure, indicating unhealthiness, when returned by a probe in active health checks.
{% endentity_params_table %}

### Disable active health checks

To completely disable active health checks for an Upstream, set `healthchecks.active.healthy.interval` and `healthchecks.active.unhealthy.interval` to `0`.

## Passive health checks (circuit breakers)

Passive health checks, also known as circuit breakers, are checks performed based on the requests proxied by {{site.base_gateway}} (HTTP/HTTPS/TCP) with no additional traffic generated.
When a Target becomes unresponsive, the passive health checker detects that and marks the Target unhealthy. 
The ring balancer starts skipping this Target and doesn't route any more traffic to it.

### Configure passive health checks

Passive health checks don't have a probe, as they work by interpreting the ongoing traffic that flows from a Target. 
To enable passive checks, you only need to configure the Upstream's counter thresholds, which you can find under `healthchecks.passive` in the [Upstream object configuration](/gateway/entities/upstream/#schema):

{% entity_params_table %}
entity: Upstream
config:
  - name: healthchecks.passive.healthy.successes
    description: Number of successes in proxied traffic (as defined by `healthchecks.passive.healthy.http_statuses`) to consider a Target healthy, as observed by passive health checks. This needs to be positive when passive checks are enabled so that healthy traffic resets the unhealthy counters.
  - name: healthchecks.passive.unhealthy.tcp_failures
    description: Number of TCP failures in proxied traffic to consider a Target unhealthy, as observed by passive health checks.
  - name: healthchecks.passive.unhealthy.timeouts
    description: Number of timeouts in proxied traffic to consider a Target unhealthy, as observed by passive health checks.
  - name: healthchecks.passive.unhealthy.http_failures
    description: Number of HTTP failures in proxied traffic (as defined by `healthchecks.passive.unhealthy.http_statuses`) to consider a Target unhealthy, as observed by passive health checks.
  - name: healthchecks.passive.healthy.http_statuses
    description: An array of HTTP statuses which represent healthiness when produced by proxied traffic, as observed by passive health checks.
  - name: healthchecks.passive.unhealthy.http_statuses
    description: An array of HTTP statuses which represent unhealthiness when produced by proxied traffic, as observed by passive health checks.
{% endentity_params_table %}

### Re-enable a Target disabled by a passive health check

Passive health checks have the advantage of not producing extra traffic, but they are unable to automatically mark a Target as healthy again. 
Once the problem with a Target is solved and it is ready to receive traffic, you have to manually inform the health checker that the Target's status is `healthy`:

```bash
curl -i -X PUT http://localhost:8001/upstreams/example-upstream/targets/10.1.2.3:1234/healthy
```

This command broadcasts a cluster-wide message so that the `healthy` status is propagated to the whole {{site.base_gateway}} cluster. 
This resets the health counters of the health checkers running in all workers of the {{site.base_gateway}} node, allowing the ring balancer to route traffic to the Target again.

### Disable passive health checks

To completely disable passive health checks for an Upstream, set all counter thresholds under `healthchecks.passive` to `0`.
