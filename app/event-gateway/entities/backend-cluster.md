---
title: "{{site.event_gateway_short}} backend clusters"
content_type: reference

description: |
    Backend clusters represent target Kafka clusters proxies by {{site.event_gateway}}.
related_resources:
  - text: "{{site.event_gateway}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Policies"
    url: /event-gateway/entities/policy/
  - text: "Backend Clusters"
    url: /event-gateway/entities/virtual-cluster/
  - text: "Listeners"
    url: /event-gateway/entities/listener/

tools:
    - konnect-api
    - terraform
tags: 
  - policy
works_on:
  - konnect

# schema:
#     api: event-gateway/
#     path: /schemas/

# api_specs:
#     - konnect/event-gateway

products:
    - event-gateway
api_specs:
    - event-gateway/knep
layout: gateway_entity

schema:
    api: event-gateway/knep
    path: /schemas/BackendCluster
---

## What is a backend cluster?

A backend cluster is an abstraction of a real Kafka cluster. It stores the connection and configuration details required for {{site.event_gateway}} to proxy traffic to Kafka.

Multiple Kafka clusters can be proxied through a single {{site.event_gateway}}. The Event Gateway control plane manages information such as:

* Authentication credentials for connecting to Kafka clusters
* TLS verification preferences
* Metadata refresh intervals for fetching cluster information

## Authentication

Authentication on the backend cluster is used to authenticate clients to the proxy. 
The backend cluster supports multiple authentication methods and can mediate authentication between clients and backend clusters.

Supported methods:

{% table %}
columns:
  - title: "Auth method (`authentication.type`)"
    key: auth
  - title: Description
    key: description
  - title: "Credential mediation types (`authentication.mediation`)"
    key: credential
rows:
  - auth: "Anonymous"
    description: "Doesn't require clients to provide any authentication when connecting to the proxy."
    credential: None
  - auth: "SASL/PLAIN"
    description: |
      Requires clients to provide a username and password.
      <br><br>
      Accepts a hardcoded list of usernames and passwords, either as strings or environment variables.
    credential: |
      `passthrough`, `terminate`
  - auth: "SASL/SCRAM-SHA-256"
    description: |
      Requires clients to provide a username and password using SCRAM-SHA-256 hashing.
    credential: |
      `passthrough` 
  - auth: "SASL/SCRAM-SHA-512"
    description: |
      Requires clients to provide a username and password using SCRAM-SHA-512 hashing.
    credential: |
      `passthrough`
{% endtable %}


## Schema

{% entity_schema %}

## Set up a backend cluster

{% navtabs "backend-cluster" %}

{% navtab "Konnect API" %}

Create a backend cluster using the [{{site.event_gateway_short}} control plane API](/):

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: example-backend-cluster
  bootstrap_servers:
    - host:9092
  authentication:
    type: anonymous
  insecure_allow_anonymous_virtual_cluster_auth: true
  tls:
    insecure_skip_verify: false
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}

{% navtab "Terraform" %}

Add the following to your Terraform configuration to create a backend cluster:

```hcl
resource "konnect_event_gateway_backend_cluster" "my_eventgatewaybackendcluster" {
provider    = konnect-beta
  authentication = {
    sasl_scram = {
    algorithm = "sha256"
    password = "${env['MY_SECRET']}"
    username = "example-username"
    }
  }
    bootstrap_servers = [
    "host:9092"
  ]
    description = "This is my backend cluster"
    gateway_id = "9524ec7d-36d9-465d-a8c5-83a3c9390458"
    insecure_allow_anonymous_virtual_cluster_auth = false
    labels = {
        key = "value"
    }
    metadata_update_interval_seconds = 22808
    name = "example-backend-cluster"
    tls = {
            ca_bundle = "example-ca-bundle"
        insecure_skip_verify = false
        tls_versions = [
            "tls12"
        ]
    }
}
```

{% endnavtab %}

{% navtab "UI" %}
The following creates a new backend cluster called **example-backend-cluster** with basic configuration:
1. In {{site.konnect_short_name}}, navigate to [**Event Gateway**](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click your event gateway.
1. Navigate to **Backend Clusters** in the sidebar.
1. Click **New backend cluster**.
1. In the **Name** field, enter `example-backend-cluster`.
1. In the **Bootstrap servers** field, enter `host:9092`.
1. From the **Authentication** dropdown menu, select "Anonymous"
1. Select the **Allow anonymous authentication from virtual clusters** checkbox.
1. Click **Save**.
{% endnavtab %}

{% endnavtabs %}