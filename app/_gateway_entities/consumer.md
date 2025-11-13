---
title: Consumers
content_type: reference
entities:
  - consumer

products:
  - gateway

tags:
  - credentials
  - authentication
  - authorization

description: A Consumer is an entity that identifies an external client that consumes or uses the APIs managed by {{site.base_gateway}}.

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /authentication/
  - text: Consumer Groups entity
    url: /gateway/entities/consumer-group/
  - text: Plugins that can be scoped to Consumers
    url: /gateway/entities/plugin/#supported-scopes-by-plugin
  - text: Consumer how-to guides
    url: /how-to/?query=consumer
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: "{{site.konnect_short_name}} control plane resource limits"
    url: /gateway/control-plane-resource-limits/

faqs:
  - q: What are credentials, and why do I need them?
    a: |
      Credentials are necessary to authenticate Consumers via various authentication mechanisms.
      The credential type depends on which authentication plugin you want to use.

      For example, a Key Authentication plugin requires an API key, and a Basic Authentication plugin requires a username and password pair.

  - q: What is the difference between Consumers and Applications?
    a: |
      Applications provide developers the ability to get access to APIs managed by {{site.base_gateway}} or {{site.konnect_short_name}} with no interaction from the Kong admin team to generate the required credentials. Applications are managed using the Developer Portal.

      With Consumers, the Kong team creates Consumers, generates credentials, and shares them with the developers that need access to the APIs.

  - q: What is the difference between Consumers and Developers?
    a: |
      A developer is a person that has registered for a Developer Portal. They can create applications and manage credentials themselves.

      Consumers are a part of your {{ site.base_gateway }} configuration and are managed by your administrators.

  - q: What is the difference between Consumers and RBAC Users?
    a: |
      RBAC Users are users of Kong Manager, whereas Consumers are users of the services proxied by the Gateway itself.

  - q: Which plugins can be scoped to Consumers?
    a: |
      Most plugins can be scoped to Consumers, with the exception of authentication plugins and plugins that control routing.

      You can see the full list in the [plugin scopes compatibility reference](/gateway/entities/plugin/#supported-scopes-by-plugin).

  - q: Can you scope authentication plugins to Consumers?
    a: |
      No. Authentication plugins must be scoped to either a Route, Service, or globally.

  - q: Can you manage Consumers with decK?
    a: |
      Yes, you can manage Consumers using decK, but take caution if you have a large number of Consumers as the sync time will be high.

      To manage a large number of Consumers using decK, we recommend a federated configuration management approach where Consumers are placed in to Consumer Groups and managed separately from the rest of your configuration.

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config
    - konnect/consumers

schema:
    api: gateway/admin-ee
    path: /schemas/Consumer

works_on:
  - on-prem
  - konnect
---

## What is a Consumer?

A Consumer is an entity that identifies an external client that consumes or uses the APIs managed by {{site.base_gateway}}.
Consumers can represent applications, services, or users who interact with your APIs.
Since they are not always human, {{site.base_gateway}} calls them Consumers, because they "consume" the service.
{{site.base_gateway}} allows you to define and manage Consumers, apply access control policies, and monitor their API usage.

Consumers are essential for controlling access to your APIs, tracking usage, and ensuring security.
They are identified by key authentication, OAuth, or other authentication and authorization mechanisms.
For example, adding a Basic Auth plugin to a Gateway Service or Route allows it to identify a Consumer, or block access if credentials are invalid.

By attaching a plugin directly to a Consumer, you can manage specific controls at the Consumer level, such as rate limits.

<!--vale off -->

{% mermaid %}
flowchart LR

Consumer(Consumer 
entity)
Service(Gateway 
Service)
Auth(Auth
plugin)
Upstream[Service 
application]
RL["Rate Limiting 
plugin"]

Client --pass
credentials--> Service
subgraph id1 ["`**KONG GATEWAY**`"]
    subgraph padding[ ]

subgraph Authenticate ["Consumer Identity Added"]
    direction LR
    Service --> Auth
    Auth--identify 
    Consumer-->Consumer
    end
end

Consumer--> RL
end
RL --apply 
per-Consumer
rate limiting--> Upstream

style Authenticate stroke-dasharray: 5 5
style padding stroke:none!important,fill:none!important

{% endmermaid %}

<!--vale on -->

## Use cases for Consumers

Common use cases for Consumers:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: "Authentication"
    description: "Client authentication is the most common reason for setting up a Consumer. If you're using an [authentication plugin](/plugins/?category=authentication), you'll need a Consumer with credentials."
  - usecase: "Rate limiting"
    description: "Rate limit specific Consumers based on tiers."
  - usecase: "Transformation"
    description: "Add or remove values from response bodies based on the Consumer."
{% endtable %}
<!--vale on-->

## Centrally-managed Consumers {% new_in 3.10 %}

Consumers can be scoped to a {{site.konnect_short_name}} region and managed centrally, or be scoped to a control plane.

Centralized Consumer management provides the following benefits:
* **Set up a Consumer identity centrally**: Only define a Consumer once, instead of defining it in multiple control planes.
* **Avoid conflicts from duplicate Consumer configuration**: Users don't need to replicate changes to Consumer identity in multiple control planes and Consumer configuration doesn't conflict.
* **Reduce configuration sync issues between the control plane and the data planes**: Consumers that are managed centrally aren't part of the configuration that is pushed down from the control plane to the data planes, so it reduces config size and latency. 

Centrally managed Consumers exist outside of control planes, so they can be used across control planes.

Use the following table to help you determine if you should use centrally-managed Consumers or Consumers scoped to control planes:

<!--vale off-->
{% feature_table %} 
columns:
  - title: "Centrally-managed Consumers"
    key: central
    center: true
  - title: Control plane scoped Consumer
    key: cp_consumer
    center: true

features:
  - title: "Share Consumer identity in more than one control plane"
    central: true
    cp_consumer: false
  - title: "Supported authentication strategies"
    central: Key auth
    cp_consumer: All
  - title: "Scope plugins directly to Consumer"
    central: false
    cp_consumer: true
  - title: "Scope plugins to Consumer Groups"
    central: true
    cp_consumer: true
{% endfeature_table %}
<!--vale on-->

You can manage Consumers centrally using the [{{site.konnect_short_name}} Consumers API](/api/konnect/consumers/v1/). 
Only Org Admins and control plane Admins have CRUD permissions for these Consumers. 

When you create a Consumer centrally, you must assign it to a realm. A realm groups Consumers around an identity, defined by organizational boundaries, such as a production realm or a development realm. 
Realms are connected to a [geographic region](/konnect-platform/geos/) in {{site.konnect_short_name}}. Additionally, centrally managed Consumers must have a [specific Key Authentication configuration](/plugins/key-auth/examples/identity-realms/) set up to allow these Consumers to authenticate.

For a complete tutorial, see [Create a centrally-managed Consumer in {{site.konnect_short_name}}](/how-to/create-centrally-managed-consumer/).

{:.info}
> **Note:** If you are using KIC to manage your data plane nodes in {{site.konnect_short_name}}, ensure that you configure the [`cluster_telemetry_endpoint`](/gateway/configuration/#cluster-telemetry-endpoint) in the data plane. You can find your specific `cluster_telemetry_endpoint` when setting up a data plane node.

## Consumer schema

{% entity_schema %}

## Set up a Consumer

{% entity_example %}
type: consumer
data:
  custom_id: example-consumer-id
  username: example-consumer
  tags:
    - silver-tier
{% endentity_example %}
