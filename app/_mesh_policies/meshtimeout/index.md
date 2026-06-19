---
title: Mesh Timeout
name: MeshTimeouts
products:
    - mesh
description: 'Specify the amount of time Dataplane will wait for a connection to be established.'
content_type: plugin
type: policy
icon: meshtimeout.png
---

{:.warning}
> This policy uses a new policy matching algorithm.
> Do **not** combine with the deprecated Timeout policy.

## TargetRef support matrix

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
    allowed_kinds: "`Mesh`, `Dataplane`, `MeshHTTPRoute`, `MeshSubset(deprecated)`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshService`, `MeshExternalService`"
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
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshSubset`, `MeshHTTPRoute`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshService`, `MeshExternalService`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}
{% endnavtabs %}

To learn more about the information in this table, see the [matching docs](/mesh/policies-introduction/).

## Configuration

This policy enables {{site.mesh_product_name}} to set timeouts on the inbound and outbound connections
depending on the protocol. Using this policy you can configure TCP and HTTP timeouts.
Timeout configuration is split into two sections: common configuration and HTTP configuration.
Common config is applied to both HTTP and TCP communication. HTTP timeouts apply only when
the service is marked as http. More on this in protocol support section.

MeshTimeout policy lets you configure multiple timeouts:

- `connectionTimeout`
- `idleTimeout`
- `http.requestTimeout`
- `http.streamIdleTimeout`
- `http.maxStreamDuration`
- `http.maxConnectionDuration`
- `http.requestHeadersTimeout`

### Timeouts explained

#### Connection timeout

Connection timeout specifies the amount of time DP will wait for a TCP connection to be established.

#### Idle timeout

For TCP connections idle timeout is the amount of time that the DP will allow a connection to exist
with no inbound or outbound activity. On the other hand when connection in HTTP time at which an inbound
or outbound connection will be terminated if there are no active streams

#### HTTP request timeout

Request timeout lets you configure how long the data plane proxy should wait for the full response.
In details, it spans between the point at which the entire request has been processed by DP and when the response has
been completely processed by DP.

#### HTTP stream idle timeout

Stream idle timeout is the amount of time that the data plane proxy will allow an HTTP/2 stream to exist with no inbound
or outbound activity.
This timeout is strongly recommended for all requests (not just streaming requests/responses) as it additionally
defends against a peer that does not open the stream window once an entire response has been buffered to be sent to a
downstream client.

{:.info}
> Stream timeouts apply even when you are only using HTTP/1.1 in your services. This is because every connection between
> data plane proxies is upgraded to HTTP/2.

#### HTTP max stream duration

Max stream duration is the maximum time that a stream’s lifetime will span. You can use this functionality
when you want to reset HTTP request/response streams periodically.

#### HTTP max connection duration

Max connection duration is the time after which an inbound or outbound connection will be drained and/or closed,
starting from when it was first established. If there are no active streams, the connection will be closed.
If there are any active streams, the drain sequence will kick-in, and the connection will be force-closed after 5
seconds.

#### HTTP request headers timeout

The amount of time that proxy will wait for the request headers to be received. The timer is activated when the first byte of the headers is received, and is disarmed when the last byte of the headers has been received.
