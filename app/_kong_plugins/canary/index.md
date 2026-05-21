---
title: 'Canary Release'
name: 'Canary Release'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Slowly roll out software changes to a subset of users'

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - traffic-control
  - upgrade

icon: canary.png

categories:
  - traffic-control

related_resources:
  - text: ACL plugin
    url: /plugins/acl/
  - text: "{{site.base_gateway}} traffic control and routing"
    url: /gateway/traffic-control-and-routing/
  - text: Upgrading {{site.base_gateway}}
    url: /gateway/upgrade/

notes: |
  The Canary plugin is not designed for a Kubernetes-native framework,
  and shouldn't be used with the {{site.kic_product_name}}. Instead, use the 
  [Gateway API](/kubernetes-ingress-controller/gateway-api/) 
  to manage canary deploys.

min_version:
  gateway: '1.0'
---

The Canary Release plugin helps minimize risk when deploying a new software version by gradually rolling out changes to a limited group of users. 
It also allows you to either roll back to the original upstream service or shift all traffic to the new version.

{:.warning}
> **Important**: The Canary plugin is not designed for a Kubernetes-native framework, and shouldn't be used with the {{site.kic_product_name}}. 
Instead, use the [Gateway API](/kubernetes-ingress-controller/gateway-api/) to manage canary deploys.

## How the Canary Release plugin works

The Canary Release plugin allows you to route traffic to two separate upstream services.

The plugin attaches to a primary upstream service through a Gateway Service, Route, or even globally,
and then the plugin configuration connects the second upstream service using its [`config.upstream_host`](/plugins/canary/reference/#schema--config-upstream-host), [`config.upstream_port`](/plugins/canary/reference/#schema--config-upstream-port), or [`config.upstream_uri`](/plugins/canary/reference/#schema--config-upstream-uri).

The Canary Release plugin supports the following modes of operation:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Configured by
    key: configured_by
rows:
  - use_case: "[Route traffic by fixed percentage](/plugins/canary/examples/route-by-fixed-percentage/)"
    configured_by: "`config.percentage`"
  - use_case: "[Route traffic by grouping Consumers into allow/deny ACL groups](/plugins/canary/examples/route-by-acl-group/)"
    configured_by: "`config.groups` parameter with the [ACL plugin](/plugins/acl/)"
  - use_case: "[Transfer traffic from one upstream service to another over a configured time period](/plugins/canary/examples/transfer-traffic-over-time/)"
    configured_by: "`config.start` and `config.duration`"
{% endtable %}
<!--vale on-->

### Determining where to route a request

The Canary Release plugin decides how to route requests to the canary based on a hash attribute ([`config.hash`](/plugins/canary/reference/#schema--config-hash)) and a given number of buckets ([`config.steps`](/plugins/canary/reference/#schema--config-steps)). Each of these buckets can be routed to primary upstream service A or secondary upstream service B.

The behavior of `steps` depends on your canary deployment type:
* **Percentage-based canary**: Steps create buckets for traffic distribution. 
For example, if you set `config.steps` to 100 and [`config.percentage`](/plugins/canary/reference/#schema--config-percentage) to 10%, the plugin creates 100 buckets and routes 10 buckets to the canary, while the remaining 90 route to the primary service.
* **Time-based canary**: Steps determine the number of increments used to gradually shift from 0% to 100% traffic over time.
For example, in a 10-hour time based canary:
   * If `config.steps` is set to 10, you will have 10 increments of 10% each, with 1 increment per hour.
   * If `config.steps` is set to 100, you will have 100 increments of 1% each, with 10 increments per hour.

The `config.hash` parameter determines which requests end up in a specific bucket, based on their `consumer`, `ip`, or `header`.
For example, if the plugin is configured to hash on Consumer, then each Consumer will consistently end up in the same bucket or increment. 
The effect is that once a Consumer's bucket switches to upstream service B, it will then always go to B. 
The same applies to hashing on IP or header.

If any specific Consumer, IP, or header is responsible for more than the average percentage of traffic, the migration may not be evenly distributed. 
For example, if the canary fixed percentage is 50%, then 50% of either the Consumers or IPs will be rerouted, but not necessarily 50% of the total requests.

When `config.hash` is set to `none`, the requests will be evenly distributed. 
Each bucket will get the same number of requests, but a Consumer or IP might be routed to either upstream service A or B on consecutive requests.

If Consumer, IP, or header can't be identified, the Canary Release plugin automatically falls back to another option, in the following order:
1. Fall back to Consumer
2. Fall back to IP
3. Fall back to `none`, evenly distributing requests across buckets

{:.info}
> This method does not apply to allowing or denying groups with ACL.

## Overriding the canary

In some cases, you may want to allow clients to pick either upstream service A or B instead of applying the configured canary rules. 
By setting [`config.canary_by_header_name`](/plugins/canary/reference/#schema--config-canary-by-header-name), clients can send the value `always` to always use the canary service (B) or send the value `never` to never use the canary service (always use A).

## Finalizing the canary

Once the canary has moved 100% of traffic over to upstream service B, the plugin is no longer needed. 
To finalize the canary release, you need to update the Gateway Service and Canary Release plugin configuration.

{:.info}
> **Note**: If the plugin is configured on a Route, then all Routes for the current Gateway Service must have completed the canary.

1. Update the [Gateway Service entity](/gateway/entities/service/) to point to upstream service B by matching it to the URL
specified by `config.upstream_host`, `config.upstream_uri`, and `config.upstream_port`.
2. Remove the Canary Release plugin.

Removing or disabling the Canary Release plugin before the canary is complete will instantly switch all traffic back to service A.

## Upstream health checks

This plugin works with both active and passive health checks. 
You can enable [Upstream health checks](/gateway/traffic-control/health-checks-circuit-breakers/) using the [`config.upstream_fallback`](/plugins/canary/reference/#schema--config-upstream-fallback) parameter.
This configuration will skip applying the canary upstream if it doesn't have at least one healthy target. 

For this configuration to take effect, the following conditions must be met:
* Point the Canary Release plugin's `config.upstream_host` to an [Upstream entity](/gateway/entities/upstream)
* [Enable health checks in the Upstream](/gateway/traffic-control/health-checks-circuit-breakers/)

