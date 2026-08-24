---
title: "`cluster` strategy not supported in the rate limiting advanced plugin for k4k8s DB-less or Kong in hybrid mode"
content_type: support
description: "The reason you're seeing the error logs is because `cluster` strategy is not supported in rate limiting advanced plugin for k4k8s DB-less or Kong deployed in hybrid mode."
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why `cluster` options are not working in rate limiting advanced plugin for k4k8s dbless or Kong in hybrid mode?"
  a: |
    Kong rejects `strategy: cluster` for the rate limiting advanced plugin on k4k8s DB-less deployments or Kong Gateway in hybrid mode — the strategy remains a valid schema value, but a dedicated check blocks it whenever the node's role isn't `traditional` or its database is `off`. Use the `redis` strategy instead so rate limiting counters sync correctly across nodes.
related_resources: []
---

## Problem

I have set a `KongPlugin` with below yaml configuration

```yaml

apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
name: default-ratelimit
config:
limit:
- 1
window_size:
- 60
identifier: ip
sync_rate: 10
strategy: cluster
plugin: rate-limiting-advanced
```

but when i try to create/apply this `KongPlugin`, it is rejected. Could you tell me why?

```

Error from server: error when creating "kongplugin.yaml": admission webhook "validations.kong.konghq.com" denied the request: KongPlugin.configuration.konghq.com "default-ratelimit" is invalid: could not validate plugin schema: schema violation ([rate-limiting-advanced] strategy 'cluster' is not supported with Hybrid deployments or DB-less mode. If you did not specify the strategy, please use 'redis' strategy, 'local' strategy or set 'sync_rate' to -1.)
```

## Solution

The reason this configuration is rejected is because the `cluster` strategy is not supported in the rate limiting advanced plugin for k4k8s DB-less or Kong deployed in hybrid mode. `cluster` remains a valid value for the plugin's `strategy` field itself (it is not removed from the schema's list of allowed values) — the rejection instead comes from a dedicated entity-level check that specifically blocks `strategy: cluster` together with a `sync_rate` other than `-1` whenever the node's role isn't `traditional` or its database is `off`, producing the schema-violation message shown above. On a current {{site.base_gateway}} version, setting `strategy: cluster` in this scenario is rejected outright at plugin-creation time with this schema-violation error, rather than being accepted and failing at runtime. For DB-less, we recommend configuring the `redis` strategy to store the rate limiting counters, which enables synching of rate limiting counters between kong nodes.
