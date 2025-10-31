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
    url: /event-gateway/entities/policy/
  - text: "Backend Clusters"
    url: /event-gateway/entities/backend-cluster/
  - text: "Listeners"
    url: /event-gateway/entities/listener/

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

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## What is a virtual cluster?

Virtual clusters are the primary way clients interact with the {{site.event_gateway_short}} proxy.
They allow you to isolate clients from each other when connecting to the same [backend cluster](/event-gateway/entities/backend-cluster/),
and provide each client with modified view while still appearing as a standard Kafka cluster.

The virtual cluster workflow operates as follows:
1. The Kafka client produces a request.
1. A listener forwards it to the correct virtual cluster.
1. The virtual cluster applies policies and proxies the modified request to the backend cluster.
1. The backend cluster, representing a Kafka cluster, receives the request and sends a response.

{% mermaid %}
flowchart LR
    A[Kafka client] --> B[Listener
    + listener policies]
    B --> C[Virtual cluster
    + consume, produce, and cluster policies]
    C --> D[Backend 
    cluster]

    D --> C --> B --> A

    style C stroke:#86e2cc
{% endmermaid %}

{:.info}
> **Note**: Each virtual cluster can only expose one backend cluster, but you can have multiple virtual clusters connected to one backend.
In other words, a single virtual cluster can't aggregate data from multiple backend clusters.

## Why use a virtual cluster?

Virtual clusters let you apply governance and security features to event streams.
This way, a single Kafka cluster can be sliced into multiple access points, each with its own security policy.

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
      Use authentication mediation to control access between clients and backend clusters. 
      {{site.event_gateway_short}} authenticates clients (for example, with OAuth tokens) and re-authenticates separately when forwarding requests to the backend.

  - use_case: "Topic and cluster virtualization"
    description: |
      Use topic and cluster virtualization to simplify change management and security. Virtual clusters can expose only a subset of topics on the backend cluster.
  
  - use_case: "Namespacing and topic rewriting"
    description: |
      Virtual clusters support [namespaces](#namespaces), which rewrite and enforce consistent prefixes for topic and consumer group names. 
      This allows you to expose clean, simple names to clients while maintaining organization on the backend.
  - use_case: "Infrastructure planning"
    description: |
      Through logical isolation, virtual clusters help organizations reduce Kafka infrastructure costs, as they eliminate the need to maintain multiple physical Kafka clusters for environment or team separation.
{% endtable %}
<!--vale on-->

### Managing multiple environments or products

You will need to increase the number of virtual clusters if you want to create multiple environments or products on top of the same physical cluster.

Here are some common patterns:

* **Environment isolation**: You can create isolated `dev`, `test`, and `prod` namespaces on top of the same physical Kafka cluster.
If you have a topic named `orders` in each virtual cluster, this will map transparently to different backend topics: `dev-orders`, `test-orders`, and `prod-orders`. 
This provides isolation and automatic name resolution per environment.

   When clients create new topics through a virtual cluster using Kafka's `CreateTopics` request, the namespace prefix is automatically applied, 
   ensuring that clients always stay within their designated namespace.

* **External partner isolation**: You can expose the same backend topic to different external partners with data filtering. 
For instance, a single `orders` topic can be exposed through separate virtual clusters (`customer-a`, `customer-b`, `customer-c`), with each customer seeing only their own orders.

* **Reverse mapping**: One backend topic (`orders`) can appear as multiple separate topics (`dev-orders`, `test-orders`, `prod-orders`) across different virtual clusters, each pre-filtered for specific users.


## Authentication

Authentication on the virtual cluster is used to authenticate clients to the proxy. 
The virtual cluster supports multiple authentication methods and can mediate authentication between clients and backend clusters.
See [Backend cluster authentication](/event-gateway/entities/backend-cluster/#authentication) to learn more.

Virtual clusters support the following auth methods:
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

### Credential mediation

With virtual clusters, you can control how client credentials are handled between the proxy and backend cluster, 
and reuse existing credentials and principals defined on the backend cluster.

Use the virtual cluster `authentication.mediation` setting to configure a mediation mode. 
Choose the mode based on your security requirements and backend cluster configuration:

* Passthrough (`passthrough`): Authentication from the client passes through the proxy to the backend without validation. This method is required for SCRAM authentication.
* Terminate (`terminate`): Checks whether the client’s connection is authorized based on their credential, and then terminates the authentication. Then, a new authentication session starts with the backend cluster. 
* Validate and forward (`validate_forward`): The client’s OAuth token is first validated by the proxy, and then sent to the backend as-is. This will “fail fast” if the token is invalid before sending it to the backend.

## Namespaces

With namespaces, you can preserve any naming systems that you have in place, and ensure they remain consistent.
Namespaces let you:
* Rewrite and enforce topics, consumer groups, and transaction IDs with a consistent prefix
* Expose topics and consumer groups through the virtual cluster

This allows you to expose clean, simple names to clients while maintaining organization on the backend.

For example, a virtual cluster exposes a topic named `orders` to the client.
Behind the scenes, this maps to `team-a-orders` on the actual Kafka cluster. The client doesn't need to know about or manage the `team-a-` prefix.
This enables transparent multitenancy, where multiple teams can share the same Kafka cluster without needing to manually prefix every topic and consumer group name in their applications.

The following examples provide some common use cases for namespaces and show how to set them up.

### Apply prefixes automatically

The most common use case for namespaces is to automatically prefix `read` and `create` operations when interacting with topics and consumer groups. 
This helps avoid overlapping from multiple tenants.

You can do this by setting a prefix on the virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: example-virtual-cluster
  destination:
    name: example-backend-cluster
  authentication:
    - type: anonymous
  dns_label: virtual-cluster-1
  acl_mode: passthrough
  namespace:
    mode: hide_prefix
    prefix: "my-prefix"
{% endkonnect_api_request %}
<!--vale on-->

In this example, the prefix `my-prefix` will be used for all consumer group and topics that connect to this virtual cluster.

### Access additional topics

Along with topics owned by a specific team, you can pull in a select group of additional topics.
This is useful when you want to:
* Consume topics owned by other teams
* Gradually migrate to a namespace while still using old topics temporarily

Here's an example configuration using a glob pattern:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: example-virtual-cluster
  destination:
    name: example-backend-cluster
  authentication:
    - type: anonymous
  dns_label: virtual-cluster-1
  acl_mode: passthrough
  namespace:
    mode: hide_prefix
    prefix: "my-prefix"
    additional:
      topics:
        - type: glob
          glob: "my-topic-*"
          conflict: warn
{% endkonnect_api_request %}
<!--vale on-->

These topics are accessed using their full unmodified names.

This example uses a glob expression to capture topics using name patterns. 
You can also pass an exact list of topics as an array:

```sh
"topics": [
  {
    "type": "exact_list",
    "list": [
      {
        "backend": "allowed_topic",
        "backend": "another_allowed_topic"
      }
    ]
  }
]
```

### Access additional consumer groups

You can access existing consumer groups to avoid migrating offsets:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: example-virtual-cluster
  destination:
    name: example-backend-cluster
  authentication:
    - type: anonymous
  dns_label: virtual-cluster-1
  acl_mode: passthrough
  namespace:
    mode: hide_prefix
    prefix: "my-prefix"
    additional:
      consumer_groups:
        - type: glob
          glob: "my-app-*"
          conflict: warn
{% endkonnect_api_request %}
<!--vale on-->
End users of this virtual cluster can use their existing, unnamespaced consumer groups. 

This example uses a glob expression to capture consumer groups using name patterns. 
You can also pass an exact list of consumer groups as an array:

```sh
"consumer_groups": [
  {
    "type": "exact_list",
    "list": [
      {
        "value": "foo",
        "value": "bar"
      }
    ]
  }
]
```

## Virtual cluster policies

Virtual clusters can be modified by policies, which let you do things like modify headers, encrypt and decrypt records, validate record schemas, and much more.

To learn more, see:
* [Policy entity reference](/event-gateway/entities/policy/)
* [All {{site.event_gateway_short}} policies](/event-gateway/policies/)

## Set up a virtual cluster

Before setting up a virtual cluster, make sure you have a [backend cluster](/event-gateway/entities/backend-cluster/) configured.
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
  acl_mode: passthrough
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

Add the following to your Terraform configuration to create a virtual cluster:

```hcl
resource "konnect_event_gateway_virtual_cluster" "my_eventgatewayvirtualcluster" {
  provider    = konnect-beta
  acl_mode    = "passthrough"
  authentication = [
    {
      sasl_plain = {
        mediation = "passthrough"
        principals = [
          {
            password = "${env['MY_SECRET']}"
            username = "example_username"
          }
        ]
      }
    }
  ]
  description = "This is my virtual cluster"
  destination = {
    name = "example-backend-cluster"
  }
  dns_label  = "vcluster-1"
  gateway_id = "9524ec7d-36d9-465d-a8c5-83a3c9390458"
  labels = {
    key = "value"
  }
  name = "my-example-virtual-cluster"
  namespace = {
    additional = {
      consumer_groups = [
        {
          glob = {
            glob = "my-topic-*"
          }
        }
      ]
      topics = [
        {
          exact_list = {
            conflict = "warn"
            exact_list = [
              {
                backend = "example-backend"
              }
            ]
          }
        }
      ]
    }
    mode   = "hide_prefix"
    prefix = "my-prefix"
  }
}
```

{% endnavtab %}
{% endnavtabs %}

## Schema

{% entity_schema %}
