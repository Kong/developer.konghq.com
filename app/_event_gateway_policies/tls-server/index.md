---
title: TLS Server
name: TLS Server
content_type: reference
description: Configure TLS settings for a server
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/EventGatewayTLSListenerPolicy

api_specs:
  - event-gateway/knep

policy_target: listener

icon: graph.svg
---

The TLS Server policy defines the certificates and keys used by the {{site.event_gateway_short}} server when the client connects to the Gateway over TLS.

{:.info}
> Note: Only one TLS Server policy can be active on a listener at a time.

Common use cases for the TLS Server policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[TLS connections](/event-gateway/policies/tls-server/examples/tls-connection/)"
    description: "Allow clients to connect to {{site.event_gateway_short}} over TLS."
  - use_case: "[TLS connections based on a condition](/event-gateway/policies/tls-server/examples/conditions/)"
    description: "Allow clients to connect to {{site.event_gateway_short}} over TLS, but only processes messages from topics that fit a certain condition."

{% endtable %}
<!--vale on-->
