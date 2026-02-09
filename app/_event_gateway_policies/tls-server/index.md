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
  api: konnect/event-gateway
  path: /schemas/EventGatewayTLSListenerPolicy

api_specs:
  - konnect/event-gateway

related_resources:
  - text: Listeners
    url: /event-gateway/entities/listener/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: "How-to: Configure SNI routing with {{site.event_gateway_short}}"
    url: /event-gateway/configure-sni-routing/

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
  - use_case: "[Example: TLS connections](/event-gateway/policies/tls-server/examples/tls-connection/)"
    description: "Allow clients to connect to {{site.event_gateway_short}} over TLS."
  - use_case: "[How-to: SNI routing with TLS](/event-gateway/configure-sni-routing/)"
    description: |
      Set up SNI routing to send traffic to multiple virtual clusters in the same {{site.event_gateway_short}} control plane without opening more ports on the data plane.
{% endtable %}
<!--vale on-->
