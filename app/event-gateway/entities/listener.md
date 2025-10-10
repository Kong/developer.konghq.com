---
title: "{{site.event_gateway_short}} listeners"
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
    path: /schemas/Listener
---

## What is a listener?

A listeners represents hostname-port or IP-port combinations that connect to TCP sockets. Listeners need at least as many ports as backend brokers if you use port mapping in a Forward to Virtual Cluster policy. For SNI routing, you can route all brokers using a listener with only one port. Ports can be expressed as a single port or range. Addresses can be IPv4, IPv6, or hostnames.

A listener can have policies that enforce TLS certificates and perform SNI routing. The listener runs at Layer 4 of the network stack. In {{site.event_gateway}}, listeners first take in the connection and then route the TCP connection to a [virtual cluster](/event-gateway/entities/virtual-cluster/) based on conditions defined in [listener policies](/event-gateway/entities/policy/#listener-policies).

Listeners can have one or more policies that define how the TCP connection is handled:
* **TLS Server Policy:** Enforces encryption, provides a certificate, and can use SNI to route connections by hostname.
* **Forward to Virtual Cluster Policy:** Routes the connection to a specific virtual cluster. Only one forward policy is allowed per listener.

## Schema

{% entity_schema %}

## Set up a Listener

{% navtabs "listener" %}

{% navtab "Konnect API" %}
Create a listener using the {{site.event_gateway_short}} control plane API:
{% konnect_api_request %}
url: /v1/event-gateways/{controlPlaneId}/listeners
status_code: 201
method: POST
body:
    name: listener-localhost
    addresses:
    - 0.0.0.0
    ports:
    - 19092
{% endkonnect_api_request %}

{% endnavtab %}

{% navtab "Terraform" %}
Add the following to your Terraform configuration to create a listener:
```hcl
resource "konnect_event_gateway_listener" "my_eventgatewaylistener" {
  provider = konnect-beta
  addresses = [
    "0.0.0.0"
  ]
  description = "My listener"
  gateway_id  = "9524ec7d-36d9-465d-a8c5-83a3c9390458"
  labels = {
    key = "value"
  }
  name = "example-listener"
  ports = [
    "19092"
  ]
}
```

{% endnavtab %}

{% navtab "UI" %}
The following creates a new Listener called **example-backend-cluster** with basic configuration:
1. In {{site.konnect_short_name}}, navigate to [**Event Gateway**](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click your event gateway.
1. In the Event Gateway sidebar, click **Listeners**.
1. Click **New listener**.
1. In the **Name** field, enter `listener-localhost`.
1. In the **Addresses** field, enter `0.0.0.0`.
1. In the **Ports** field, enter `19092`.
1. Click **Save and add policy next**.
1. Click **Maybe later** to create a listener without a policy.
{% endnavtab %}

{% endnavtabs %}
