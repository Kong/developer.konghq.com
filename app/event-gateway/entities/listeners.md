---
title: "{{site.event_gateway}} Listeners"
content_type: reference
layout: reference

description: |
    Listeners represent the network interface for Kafka client connections over TCP.
related_resources:
  - text: "{{site.event_gateway}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Policies"
    url: /event-gateway/entities/policies/
  - text: "Virtual clusters"
    url: /event-gateway/entities/virtual-clusters/
  - text: "Backend clusters"
    url: /event-gateway/entities/backend-clusters/

tools:
    - konnect-api
    - terraform

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

## What is a Listener?

A listeners represents hostname-port or IP-port combinations that connect to TCP sockets. A listener can have policies that enforce TLS certificates and perform SNI routing. The listener runs at Layer 4 of the network stack.

In {{site.event_gateway}}, listeners first take in the connection and then route the TCP connection to a [virtual cluster](/event-gateway/entities/virtual-clusters/) based on conditions defined in [listener policies](/event-gateway/entities/policies/#listener-policies).


## Schema

{% entity_schema %}

## Set up a Listener

{% navtabs "listener" %}

{% navtab "Konnect API" %}

```sh
curl -X POST https://{region}.api.konghq.com/v1/event-gateways/{controlPlaneId}/listeners \
    --header "accept: application/json" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $KONNECT_TOKEN" \
    --data '
    {
       "name": "listener-localhost",
       "addresses": [
         "0.0.0.0"
       ],
       "ports": [
         "19092"
       ]
     }
    '
```
{% endnavtab %}

{% navtab "Terraform" %}
TODO
```sh
resource "konnect_gateway_backend-cluster" "my_backend-cluster" {
  addresses = ["0.0.0.0"]
  ports = ["19092"]

  control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
}
```
{% endnavtab %}

{% navtab "UI" %}
The following creates a new Listener called **example-backend-cluster** with basic configuration:
1. In {{site.konnect_short_name}}, navigate to [**Event Gateway**](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click your event gateway.
1. Navigate to **Listeners** in the sidebar.
1. Click **New listener**.
1. In the **Name** field, enter `listener-localhost`.
1. In the **Addresses** field, enter `0.0.0.0`.
1. In the **Ports** field, enter `19092`.
1. Click **Save and add policy next**.
1. Click **Mayber later** to create a listener without a policy.
{% endnavtab %}

{% endnavtabs %}
