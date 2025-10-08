---
title: "{{site.event_gateway}} Backend Clusters"
content_type: reference

description: |
    Backend clusters represent target Kafka clusters proxies by {{site.event_gateway}}.
related_resources:
  - text: "{{site.event_gateway}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Policies"
    url: /event-gateway/entities/policies/
  - text: "Virtual Clusters"
    url: /event-gateway/entities/virtual-clusters/
  - text: "Listeners"
    url: /event-gateway/entities/listeners/

tools:
    - konnect-api
    - terraform

entities:
 - backend-cluster

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
    path: /schemas/BackendCluster
---

## What is a Backend Cluster?

A backend cluster in {{site.konnect_short_name}} is an abstraction a real Kafka cluster that runs in your environment. The backend cluster contains the connection details to the Kafka cluster proxied by {{site.event_gateway}}.

There can be multiple Kafka clusters proxied through the same gateway. {{site.event_gateway}} control planes store information about how to authenticate to Kafka clusters, whether or not to verify the cluster’s TLS certificates, and how often to fetch metadata from the clusters. 

## Schema

{% entity_schema %}

## Set up a Backend Cluster

{% navtabs "backend-cluster" %}

{% navtab "Konnect API" %}

```sh
curl -X POST https://{region}.api.konghq.com/v1/event-gateways/{controlPlaneId}/backend-clusters \
    --header "accept: application/json" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $KONNECT_TOKEN" \
    --data '
    {
      "name": "example",
      "bootstrap_servers": [
        "host:9092"
      ],
      "authentication": {
        "type": "anonymous"
      },
      "insecure_allow_anonymous_virtual_cluster_auth": true,
      "tls": {
        "insecure_skip_verify": false
      }
    }
    '
```
{% endnavtab %}

{% navtab "Terraform" %}
TODO
```sh
resource "konnect_event_gateway_backend_cluster" "my_eventgatewaybackendcluster" {
  bootstrap_servers = [
    "kafka:9092"
  ]
  authentication = {
    type = "anonymous"
  }
  insecure_allow_anonymous_virtual_cluster_auth = true
  tls = {
    insecure_skip_verify = false
  }
  name = "example-backend-cluster"
  metadata_update_interval_seconds = 60
  gateway_id = konnect_event_gateway.my_eventgateway.id
}
```
{% endnavtab %}

{% navtab "UI" %}
The following creates a new Backend Cluster called **example-backend-cluster** with basic configuration:
1. In {{site.konnect_short_name}}, navigate to [**Event Gateway**](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click your event gateway.
1. Navigate to **Backend Clusters** in the sidebar.
1. Click **New backend cluster**.
1. In the **Name** field, enter `example-backend-cluster`.
1. In the **Bootstrap servers** field, enter `kafka:9092`.
1. From the **Authentication** dropdown menu, select "Anonymous"
1. Select the **Allow anonymous authentication from virtual clusters** checkbox.
1. Click **Save**.
{% endnavtab %}

{% endnavtabs %}