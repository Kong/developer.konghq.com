---
title: "Schema registry"
content_type: reference
layout: gateway_entity

description: |
    Schema registries are resources that let you validate messages against the Confluent schema registry.
related_resources:
  - text: "Schema Validation - produce policy"
    url: /event-gateway/policies/schema-validation-produce/
  - text: "Schema Validation - consume policy"
    url: /event-gateway/policies/schema-validation-consume/
tools:
    - konnect-api
    - terraform

works_on:
  - konnect

schema:
    api: event-gateway/knep
    path: /schemas/SchemaRegistry

api_specs:
    - event-gateway/knep

products:
    - event-gateway

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## What is a schema registry?

Schema registries are resources that you can use in [Schema Validation policies](/event-gateway/policies/)
to validate messages against the [Confluent schema registry](https://docs.confluent.io/platform/current/schema-registry/index.html).

{{site.event_gateway_short}} supports the following registry types:
* Avro
* JSON Schema

## Set up a schema registry

{% navtabs "schema-registry" %}

{% navtab "Konnect API" %}

To create a schema registry, make a POST request to the `/schema-registries` endpoint of the {{site.event_gateway_short}} control plane API.
For example, to create a Confluent schema registry:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/schema-registries
status_code: 201
method: POST
body:
  name: my-schema-registry
  type: confluent
  config:
    schema_type: avro
    endpoint: endpoint
    timeout_seconds: 10
    authentication:
      type: basic
      username: username
      password: $MY_PASSWORD
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}

{% navtab "Terraform" %}

Add the following to your Terraform configuration to create a schema registry:

```hcl
resource "konnect_event_gateway_schema_registry" "my_eventgatewayschemaregistry" {
  provider = konnect-beta
  confluent = {
      config = {
        authentication = {
          basic = {
              password = "${env['MY_SECRET']}"
              username = "...my_username..."
            }
          }
        endpoint = "https://key-hovercraft.com"
        schema_type = "avro"
        timeout_seconds = 8
      }
      description = "...my_description..."
      labels = {
          key = "value"
      }
      name = "example-schema-registry"
  }
      gateway_id = "9524ec7d-36d9-465d-a8c5-83a3c9390458"
  }
```

{% endnavtab %}

{% navtab "UI" %}

1. In the sidebar, navigate to **Event Gateway**.

1. Click an {{site.event_gateway_short}}.

1. In the Gateway's sidebar, navigate to **Resources**.

1. Click **New Schema Registry**.

1. Configure your schema registry.

1. Click **Create**.

{% endnavtab %}

{% endnavtabs %}

## Schema

{% entity_schema %}
