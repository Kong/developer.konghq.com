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
    url: /event-gateway/entities/virtual-clusters/
  - text: "Backend clusters"
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
    path: /schemas/EventGatewayPolicy

api_specs:
    - event-gateway/knep

products:
    - event-gateway
---

## What is an {{site.event_gateway_short}} policy?

Policies control how Kafka protocol traffic is modified between the client and the backend cluster.

There are two main types of policies:
* **Virtual cluster policies**: Policies applied to Kafka traffic via [virtual clusters](/event-gateway/entities/virtual-clusters/), letting you do things like modify headers, encrypt and decrypt records, validate record schemas, and much more.
* **Listener policies**: Policies applied to layer 4 TCP traffic on [listeners](/event-gateway/entities/listeners/), 
for example to enforce TLS, select a certificate for the TLS connection, or to route to a specific virtual cluster.

[See all policies](/event-gateway/policies/)

## Virtual cluster policies 

[See all virtual cluster policies](/event-gateway/policies/#virtual-cluster-policies)

### Phases

Virtual cluster policies execute in specific phases. Phases are stages of a record's lifecycle.

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

Some policies require the record to be marshalled, while others can act on marshaled records or parsed records.
* Marshaled records are serialized, raw data
* Parsed records are deserialized back into a structured format

{% feature_table %}
columns:
  - title: Can act on parsed record?
    key: parsed
    center: true
features:
  - title: "[Kafka ACL](/event-gateway/policies/acl/)"
    parsed: No
  - title: "[Encrypt](/event-gateway/policies/encrypt/)"
    parsed: No
  - title: "[Decrypt](/event-gateway/policies/decrypt/)"
    parsed: No
  - title: "[Schema validation](/event-gateway/policies/schema-validation/)"
    parsed: No
  - title: "[Modify headers](/event-gateway/policies/modify-headers/)"
    parsed: Yes
  - title: "[Skip records](/event-gateway/policies/skip-records/)"
    parsed: Yes
{% endfeature_table %}

### Conditions

Policies have a condition field that determines whether the policy executes or not. 
Within this condition, you can access dynamic configuration from the execution context. 

TO DO: Explain what this means in detail.

### Set up a virtual cluster policy

{{site.event_gateway}} has a few built-in virtual cluster policies, all of which have their own specific configurations and examples. 
See all [{{site.event_gateway_short}} policies](/event-gateway/policies/#virtual-cluster-policies) for their individual configurations.

{% navtabs 'virtual-cluster' %}
{% navtab "Konnect API" %}

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

If you don't have a virtual cluster yet:

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

If you don't have a virtual cluster:

1. In the sidebar, navigate to **Event Gateway**.

1. Click an {{site.event_gateway_short}}.

1. In the Gateway's sidebar, navigate to **Virtual Clusters**.

1. Configure the virtual cluster:

{{ ui | indent: 4 }}


{% endnavtab %}
{% navtab "Terraform" %}

TO DO

{% endnavtab %}
{% endnavtabs %}

## Listener policies

[See all listener policies](/event-gateway/policies/#listener-policies)

### Set up a listener policy

{{site.event_gateway}} has a few built-in listener policies, all of which have their own specific configurations and examples. 
See all [{{site.event_gateway_short}} policies](/event-gateway/policies/#listener-policies) for their individual configurations.

{% navtabs 'listener-policy' %}
{% navtab "Konnect API" %}

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

TO DO

{% endnavtab %}
{% endnavtabs %}


## Schema

{% entity_schema %}