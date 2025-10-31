---
title: "Listeners"
content_type: reference

description: |
    Listeners represent the network interface for Kafka client connections over TCP.
related_resources:
  - text: "{{site.event_gateway}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Policies"
    url: /event-gateway/entities/policy/
  - text: "Virtual clusters"
    url: /event-gateway/entities/virtual-cluster/
  - text: "Backend clusters"
    url: /event-gateway/entities/backend-cluster/

tools:
    - konnect-api
    - terraform
works_on:
  - konnect
tags:
  - policy

# schema:
#     api: event-gateway/
#     path: /schemas/

# api_specs:
#     - konnect/event-gateway

products:
    - event-gateway

layout: gateway_entity

schema:
    api: event-gateway/knep
    path: /schemas/EventGatewayListener

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## What is a listener?

A listeners represents hostname-port or IP-port combinations that connect to TCP sockets. Listeners need at least as many ports as backend brokers if you use port mapping in a Forward to Virtual Cluster policy. For SNI routing, you can route all brokers using a listener with only one port. Ports can be expressed as a single port or range. Addresses can be IPv4, IPv6, or hostnames.

A listener can have policies that enforce TLS certificates and perform SNI routing. The listener runs at Layer 4 of the network stack. In {{site.event_gateway}}, listeners first take in the connection and then route the TCP connection to a [virtual cluster](/event-gateway/entities/virtual-cluster/) based on conditions defined in [listener policies](/event-gateway/entities/policy/#listener-policies).

{% include_cached /knep/entities-diagram.md entity="B" %}

Listeners can have one or more policies that define how the TCP connection is handled:
* **TLS Server Policy:** Enforces encryption, provides a certificate, and can use SNI to route connections by hostname.
* **Forward to Virtual Cluster Policy:** Routes the connection to a specific virtual cluster. Only one forward policy is allowed per listener.

## Set up a listener

{% entity_example %}
type: listener
data:
    name: listener-localhost
    addresses:
    - 0.0.0.0
    ports:
    - 19092
{% endentity_example %}

## Schema

{% entity_schema %}
