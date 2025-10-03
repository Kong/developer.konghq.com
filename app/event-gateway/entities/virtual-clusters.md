---
title: "Virtual clusters"
content_type: reference
layout: gateway_entity

description: |
    Virtual clusters are {{site.event_gateway_short}} entities that expose a modified view of the backend cluster to clients.
related_resources:
  - text: "{{site.event_gateway}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Policies"
    url: /event-gateway/entities/policies/
  - text: "Backend Clusters"
    url: /event-gateway/entities/backend-clusters/
  - text: "Listeners"
    url: /event-gateway/entities/listeners/

tools:
    - konnect-api
    - terraform
tags:
  - policy

works_on:
  - konnect

schema:
    api: event-gateway/knep
    path: /schemas/VirtualCluster

api_specs:
    - event-gateway/knep

products:
    - event-gateway
---

## What is a virtual cluster?

Virtual clusters are the primary way clients interact with the {{site.event_gateway_short}} proxy. 
They allow you to isolate clients from each other when connecting to the same [backend cluster](/event-gateway/entities/backend-clusters/), 
and provide each client with modified view while still appearing as a standard Kafka cluster.

Here's how it works:
1. The Kafka client produces an event.
1. A listener forwards it to the correct virtual cluster.
1. The virtual cluster applies policies and proxies the modified event data to the backend cluster.
1. The backend cluster, representing a Kafka cluster, receives data and sends a response.

{% mermaid %}
flowchart LR
    A[Kafka client] --> B[Listener
    + listener policies]
    B --> C[Virtual cluster
    + consume, produce, and cluster policies]
    C --> D[Backend 
    cluster]

    style C fill:#cee1ff,stroke-width:2px
{% endmermaid %}

{:.info}
> **Note**: Each virtual cluster can only expose one backend cluster, but you can have multiple virtual clusters connected to one backend.

## Why use a virtual cluster?

Virtual clusters let you apply governance and security features to event streams.
This way, a single Kafka cluster can to be sliced into multiple endpoints, each with its own security policy.

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "Policy enforcement"
    description: |
      Define policies on virtual clusters to govern client behavior. Policies include transformations, filtering, enforcing encryption and decryption standards, access control, and more.

  - use_case: "Authentication and mediation"
    description: |
      Manage client authentication to the proxy with authentication mediation. 
      {{site.event_gateway_short}} can validate client credentials (like an OAuth token) before using separate credentials to connect to the upstream backend cluster.

  - use_case: "Topic and cluster virtualization"
    description: |
      Use topic and cluster virtualization to simplify change management and security. Virtual clusters can expose only a subset of topics on the backend cluster.
  
  - use_case: "Namespacing and topic rewriting"
    description: |
      Virtual clusters support Namespaces, which rewrite and enforce consistent prefixes for topic and consumer group names, exposing specific topics and consumer groups. 
      For example, a virtual cluster might expose a topic named `orders`, which internally maps to a physical topic like `dev-orders` or `prod-orders` on the backend cluster.
  
  - use_case: Cost optimization
    description: |
      Through logical isolation, virtual clusters help organizations reduce Kafka infrastructure costs, as they eliminate the need to maintain multiple physical Kafka clusters for environment separation.
{% endtable %}
<!--vale on-->

### Managing multiple environments or products

You will need to increase the number of virtual clusters if you want to create multiple environments or products on top of the same physical cluster.

Here are some examples:

* **Environment isolation**: You can create isolated `dev`, `test`, and `prod` namespaces on top of the same physical Kafka cluster.
If you have a topic named `orders` in each virtual cluster, it can map to different backend topics: `dev-orders`, `test-orders`, and `prod-orders`. 
This provides isolation and automatic name resolution per environment.

* **External partner isolation**: You can expose the same backend topic to different external partners with data filtering. 
For instance, a single `orders` topic can be exposed through separate virtual clusters (`customer-a`, `customer-b`, `customer-c`), with each customer seeing only their own orders.

* **Reverse mapping**: One backend topic (`orders`) can appear as multiple separate topics (`dev-orders`, `test-orders`, `prod-orders`) across different virtual clusters, each pre-filtered for specific users.

Destination - this is the target backend cluster. Right now there is only one backend cluster configurable per virtual cluster [expect this change in the future].

## Authentication

Authentication on the virtual cluster is used to authenticate clients to the proxy. 
The virtual cluster supports multiple authentication methods and can mediate authentication between clients and backend clusters.

The following auth methods are supported:

{% table %}
columns:
  - title: Auth method
    key: auth
  - title: Description
    key: description
  - title: Credential mediation types
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
  - auth: "SASL/OAUTHBEARER"
    description: |
      Requires clients to provide an OAuth token and a JWKS endpoint to verify token signatures, optionally with claim mapping and validation rules.
    credential: |
      `passthrough`, `terminate`, `validate_forward`
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

### Credential modes

When performing authentication mediation, you can control how client credentials are handled between the proxy and backend cluster. 
This enables reuse of existing credentials and principals defined on the backend cluster.

Choose credential forwarding modes based on your security requirements and backend cluster configuration:

* Passthrough: Authentication from the client passes through the proxy to the backend without validation.
* Terminate: Checks whether the client’s connection is authorized based on their credential, and then terminates the authentication. Then, a new authentication session starts with the backend cluster. 
* Validate and forward: The client’s OAuth token is first validated by the proxy, and then sent to the backend as-is. This will “fail fast” if the token is invalid before sending it to the backend.

## Virtual cluster policies

Virtual clusters can be modified by policies. 

## Set up a virtual cluster

Before setting up a virtual cluster, make sure you have a [backend cluster](/event-gateway/entities/backend-clusters/) configured. 
A virtual cluster must connect to an existing backend cluster.

{% navtabs 'virtual-cluster' %}
{% navtab "Konnect API" %}

Create a virtual cluster using the [{{site.event_gateway_short}} control plane API](/):

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: example-name
  destination:
    name: example-backend-cluster
  authentication:
    - type: anonymous
  dns_label: virtual-cluster-1
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Konnect UI" %}

1. In the sidebar, navigate to **Event Gateway**.

1. Click an {{site.event_gateway_short}}.

1. In the Gateway's sidebar, navigate to **Virtual Clusters**.

1. Click **New Virtual Cluster**.

1. Configure your virtual cluster.

1. Click **Save and add policy**.

At this point, you can choose to add a policy, or exit out and add a policy later.

{% endnavtab %}
{% navtab "Terraform" %}

TO DO

{% endnavtab %}
{% endnavtabs %}

## Schema

{% entity_schema %}
