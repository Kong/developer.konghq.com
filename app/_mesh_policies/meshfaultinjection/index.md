---
title: Mesh Fault Injection
name: MeshFaultInjections
products:
    - mesh
description: 'Test services for resiliency by introducing errors.'
content_type: plugin
type: policy
icon: meshfaultinjection.png
---

{:.warning}
> This policy uses a new policy matching algorithm.
> Do **not** combine with the now deprecated FaultInjection policy.

## `targetRef` support matrix

{% navtabs "support-matrix" %}
{% navtab "Sidecar" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `Dataplane`, `MeshSubset(deprecated)`"
  - targetref: "`from[].targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshSubset`, `MeshServiceSubset`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Built-in Gateway" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`Mesh`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Delegated Gateway" %}

`MeshFaultInjection` isn't supported on delegated gateways.

{% endnavtab %}
{% endnavtabs %}



## Configuration

`MeshFaultInjection` lets you configure a list of HTTP faults. They execute in the same order as they were defined.

```yaml
default:
  http:
    - abort:
        httpStatus: 500
        percentage: "2.5"
      delay:
        value: 5s
        percentage: 5
      responseBandwidth:
        limit: "50Mbps"
        percentage: 50
    - abort:
        httpStatus: 500
        percentage: 10
    - delay:
        value: 5s
        percentage: 5
```

It's worth mentioning that percentage of the next filter depends on the percentage of previous ones.

```yaml
http:
  - abort:
      httpStatus: 500
      percentage: 70
  - abort:
      httpStatus: 503
      percentage: 50
```
That means that for 70% of requests, it returns 500 and for 50% of the 30% that passed it returns 503.

### Abort

Abort defines a configuration of not delivering requests to destination service and replacing the responses from destination data plane by
predefined status code.

- `httpStatus` - HTTP status code returned to the source side, in the [100 - 599] range
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### Delay

Delay defines a configuration of delaying a response from a destination.

- `value` - the duration during which the response is delayed
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### ResponseBandwidth limit

ResponseBandwidth defines a configuration to limit the speed of responding to requests.

- `limit` - represented by value measure in Gbps, Mbps, kbps, or bps, for example `10kbps`
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.
