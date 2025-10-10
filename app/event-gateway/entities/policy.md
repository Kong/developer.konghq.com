---
title: "{{site.event_gateway_short}} Policies"
content_type: reference
layout: gateway_entity

description: |
    Policies control how Kafka protocol traffic is modified between the client and the backend cluster.
related_resources:
  - text: "{{site.event_gateway_short}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Virtual clusters"
    url: /event-gateway/entities/virtual-cluster/
  - text: "Backend clusters"
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
    path: /schemas/EventGatewayPolicy

api_specs:
    - event-gateway/knep

products:
    - event-gateway
---

## What is an {{site.event_gateway_short}} policy?

Policies control how Kafka protocol traffic is modified between the client and the backend cluster.

There are two main types of policies:
* [Virtual cluster policies](#virtual-cluster-policies)
* [Listener policies](#listener-policies)

## Virtual cluster policies 

Virtual cluster policies are applied to Kafka traffic via [virtual clusters](/event-gateway/entities/virtual-clusters/). They let you modify headers, encrypt or decrypt records, validate schemas, and more.

See the {{site.event_gateway}} policy hub for [all available virtual cluster policies](/event-gateway/policies/?policy-target=virtual_cluster).

### Phases

Virtual cluster policies run during specific phases, which represent stages in a record's lifecycle.

{% table %}
columns:
  - title: Phase
    key: phase
  - title: Description
    key: description
  - title: Policies
    key: policies
rows:
  - phase: "`Cluster`"
    description: Cluster policies execute on all Kafka API commands from clients.
    policies: |
        - [ACL](/event-gateway/policies/acl/)
  - phase: "`Produce`"
    description: "Produce policies execute on Kafka `Produce` commands."
    policies: |
        - [Encrypt](/event-gateway/policies/encrypt/)
        - [Schema validation](/event-gateway/policies/schema-validation/)
        - [Modify headers](/event-gateway/policies/modify-headers/)
  - phase: "`Consume`"
    description: "Consume policies execute on Kafka `Fetch` commands."
    policies: |
        - [Decrypt](/event-gateway/policies/decrypt/)
        - [Schema validation](/event-gateway/policies/schema-validation/)
        - [Modify headers](/event-gateway/policies/modify-headers/)
        - [Skip records](/event-gateway/policies/skip-records/)
{% endtable %}

### Record serialization

Some policies operate on parsed records, while others work with raw serialized data.

* **Parsed records**: Deserialized into a structured format (for example, JSON objects or Avro records).
* **Non-parsed records**: Raw, serialized byte data.

Records are deserialized on produce and re-serialized on consume.

{% feature_table %}
columns:
  - title: Can act on parsed (deserialized) record?
    key: parsed
    center: true
  - title: Can act on non-parsed (serialized) record?
    key: nonparsed
    center: true
features:
  - title: "[Kafka ACL](/event-gateway/policies/acl/)"
    parsed: No
    nonparsed: Yes
  - title: "[Encrypt](/event-gateway/policies/encrypt/)"
    parsed: No
    nonparsed: Yes
  - title: "[Decrypt](/event-gateway/policies/decrypt/)"
    parsed: No
    nonparsed: Yes
  - title: "[Schema validation](/event-gateway/policies/schema-validation/)"
    parsed: No
    nonparsed: Yes
  - title: "[Modify headers](/event-gateway/policies/modify-headers/)"
    parsed: Yes
    nonparsed: Yes
  - title: "[Skip records](/event-gateway/policies/skip-records/)"
    parsed: Yes
    nonparsed: Yes
{% endfeature_table %}

### Set up a virtual cluster policy

{{site.event_gateway}} has a few built-in virtual cluster policies, all of which have their own specific configurations and examples. 
See all [{{site.event_gateway_short}} policies](/event-gateway/policies/#virtual-cluster-policies) for their individual configurations.

{% navtabs 'virtual-cluster' %}
{% navtab "Konnect API" %}

{% include_cached /knep/entity-example-token-api.md %}

Create a virtual cluster policy using the [{{site.event_gateway_short}} control plane API](/).

Here's an example configuration of the Encrypt produce policy:
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/{gatewayId}/virtual-clusters/{virtualClusterId}/produce-policies
status_code: 201
method: POST
body:
  name: example-encrypt-policy
  type: encrypt
  enabled: true
  config:
    failure_mode: error
    key_sources:
      - type: aws
    encrypt:
      - part_of_record: key
        key_id: static://static-key-named-in-source
{% endkonnect_api_request %}
<!--vale on-->

Here's an example configuration of the Decrypt consume policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/{gatewayId}/virtual-clusters/{virtualClusterId}/consume-policies
status_code: 201
method: POST
body:
  name: example-decrypt-policy
  type: decrypt
  enabled: true
  config:
    decrypt:
      - part_of_record: key
    failure_mode: error
    key_sources:
      - type: aws
{% endkonnect_api_request %}
<!--vale on-->


<!-- For a cluster policy:

{% konnect_api_request %}
url: /v1/event-gateways/{gatewayId}/virtual-clusters/{virtualClusterId}/cluster-policies
status_code: 201
method: POST
body:
  name: example-name
{% endkonnect_api_request %} -->


{% endnavtab %}
{% navtab "Konnect UI" %}

{% capture ui %}
{% navtabs 'ui' %}
{% navtab "New Virtual Cluster" %}

If you don't have an existing Virtual Cluster, create one: 

1. Click **New Virtual Cluster**.
1. Configure your virtual cluster.
1. Click **Save and add policy**.
1. Choose a policy.
1. Configure the policy.
1. Click **Save**.

{% endnavtab %}
{% navtab "Existing Virtual Cluster" %}
If you already have a virtual cluster and want to apply a policy to it:

1. Click a virtual cluster.
1. Click the **Policies** tab.
1. Click **New Policy**.
1. Choose a policy phase and policy type.
1. Click **Configure**.
1. Configure the policy.
1. Click **Save**.

{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

If you don't have an existing Virtual Cluster, create one: 

1. In the sidebar, navigate to **Event Gateway**.

1. Click an {{site.event_gateway_short}}.

1. In the Gateway's sidebar, navigate to **Virtual Clusters**.

1. Configure the virtual cluster:

{{ ui | indent: 4 }}


{% endnavtab %}
{% navtab "Terraform" %}

{% include_cached /knep/entity-example-token-terraform.md %}

Add the following to your Terraform configuration to create a virtual cluster policy.

Here's an example configuration of the Encrypt produce policy:

```hcl
resource "konnect_event_gateway_produce_policy_encrypt" "my_eventgatewayproducepolicyencrypt" {
  provider           = konnect-beta
  condition          = "context.topic.name.endsWith('my_suffix')"
  config = {
    encrypt = [
      {
        key_id         = "static://static-key-named-in-source"
        part_of_record = "value"
      }
    ]
    failure_mode = "error"
    key_sources = [
      {
        static = {
          keys = [
            {
              id  = "...my_id..."
              key = "${env['MY_SECRET']}"
            }
          ]
        }
      }
    ]
  }
  description        = "...my_description..."
  enabled            = true
  gateway_id         = "9524ec7d-36d9-465d-a8c5-83a3c9390458"
  labels = {
    key = "value"
  }
  name               = "...my_name..."
  parent_policy_id   = "d360a229-0d2f-4566-9b8e-dad95ffde3d0"
  virtual_cluster_id = "6ea3798e-38ca-4c28-a68e-1a577e478f2c"
}
```

Here's an example configuration of the Decrypt consume policy:

```hcl
resource "konnect_event_gateway_consume_policy_decrypt" "my_eventgatewayconsumepolicydecrypt" {
  provider           = konnect-beta
  condition          = "context.topic.name.endsWith('my_suffix')"
  config = {
    decrypt = [
      {
        part_of_record = "key"
      }
    ]
    failure_mode = "passthrough"
    key_sources = [
      {
        aws = {
          # ...
        }
      }
    ]
  }
  description        = "...my_description..."
  enabled            = false
  gateway_id         = "9524ec7d-36d9-465d-a8c5-83a3c9390458"
  labels = {
    key = "value"
  }
  name               = "...my_name..."
  parent_policy_id   = "969447b3-1e41-42d8-a020-1ebc4e88a916"
  virtual_cluster_id = "05c6c607-3c42-45e9-a9e8-3e6338120724"
}
```

{% endnavtab %}
{% endnavtabs %}

## Listener policies

Listener policies are applied to layer 4 TCP traffic on [listeners](/event-gateway/entities/listeners/), 
for example to enforce TLS, select a certificate for the TLS connection, or to route to a specific virtual cluster.

See the {{site.event_gateway}} policy hub for [all available listener policies](/event-gateway/policies/?policy-target=listener).

### Set up a listener policy

{{site.event_gateway}} has a few built-in listener policies, all of which have their own specific configurations and examples. 
See all [{{site.event_gateway_short}} policies](/event-gateway/policies/#listener-policies) for their individual configurations.

{% navtabs 'listener-policy' %}
{% navtab "Konnect API" %}

{% include_cached /knep/entity-example-token-api.md %}

Create a listener policy using the [{{site.event_gateway_short}} control plane API](/).
For example, here's a configuration for the Forward to Virtual Cluster policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/policies
status_code: 201
method: POST
body:
  name: example-forward-policy
  type: forward_to_virtual_cluster
  enabled: true
  config:
    advertised_host: 127.0.0.1
    bootstrap_port: at_start
    destination:
      id: 0199a6e2-eb23-7976-a595-e955b91843d5
      name: example
    min_broker_id: 1
    type: port_mapping
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Konnect UI" %}

1. In the sidebar, navigate to **Event Gateway**.

1. Click an {{site.event_gateway_short}}.

1. In the Gateway's sidebar, navigate to **Listeners**.

1. Configure the virtual cluster:

{% capture ui %}
{% navtabs 'ui' %}
{% navtab "New Listener" %}

If you don't have a listener configured:

1. Click **New Listener**.
1. Configure your listener.
1. Click **Save and add policy**.
1. Choose a policy.
1. Configure the policy.
1. Click **Save**.

{% endnavtab %}
{% navtab "Existing Listener" %}

If you already have a listener and want to apply a policy to it:

1. Click a listener
1. Click the **Policies** tab.
1. Click **New Policy**.
1. Choose a policy type.
1. Click **Configure**.
1. Configure the policy.
1. Click **Save**.
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

{{ ui | indent: 4 }}

{% endnavtab %}
{% navtab "Terraform" %}

{% include_cached /knep/entity-example-token-terraform.md %}

Add the following to your Terraform configuration to create a listener policy.

For example, here's how to create a Forward to Virtual Cluster policy:

```hcl
resource "konnect_event_gateway_listener_policy_forward_to_virtual_cluster" "my_eventgatewaylistenerpolicyforwardtovirtualcluster" {
  provider  = konnect-beta
  condition = "context.topic.name.endsWith('my_suffix')"
  config = {
    sni = {
      advertised_port = 61579
      sni_suffix      = ".example.com"
    }
  }
  description               = "...my_description..."
  enabled                   = false
  event_gateway_listener_id = "6feda708-3b1b-4415-b1db-cf2694f34b09"
  gateway_id                = "9524ec7d-36d9-465d-a8c5-83a3c9390458"
  labels = {
    key = "value"
  }
  name = "...my_name..."
}
```

{% endnavtab %}
{% endnavtabs %}

## Conditions

Policies have a condition field that determines whether the policy executes or not. 
By writing conditions using expressions, you can access dynamic configuration from the execution context.

For policy conditions and template strings, {{site.event_gateway}} supports a subset of JavaScript operators and expressions:

* Logical operators: `&&`, `||`, `!`
* Comparison operators: `==`, `!=`, `<`, `<=`, `>`, `>=`
* Concatenation operator: `+`
* Functions: the following string functions:
  * `includes`
  * `startsWith` 
  * `endsWith`
  * `substring`

<!-- To do when info exists: create separate reference page for expressions -->

For example, you can create a condition that selects all topics that end with the suffix `my_suffix`:

```json
"condition": "context.topic.name.endsWith('my_suffix')"
```

Conditions must be between 1 and 1000 characters long.

## Schema

{% entity_schema %}