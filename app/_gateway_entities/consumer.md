---
title: Consumers
content_type: reference
entities:
  - consumer # we could use this to pull the schema too

description: A Consumer typically refers to an entity that consumes or uses the APIs managed by {{site.base_gateway}}.

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /authentication/
  - text: Consumer Groups entity
    url: /gateway/entities/consumer-group/
  - text: Plugins that can be scoped to Consumers
    url: /gateway/entities/plugin/#supported-scopes-by-plugin
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: Create a centrally-managed Consumer in {{site.konnect_short_name}}
    url: /how-to/create-centrally-managed-consumer/

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

schema:
    api: gateway/admin-ee
    path: /schemas/Consumer

works_on:
  - on-prem
  - konnect
---

## What is a Consumer?

A Consumer is an entity that consumes or uses the APIs managed by {{site.base_gateway}}.
Consumers can be applications, services, or users who interact with your APIs.
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
per-Consume
rate limiting--> Upstream

style Authenticate stroke-dasharray: 5 5
style padding stroke:none!important,fill:none!important

{% endmermaid %}

<!--vale on -->

## Use cases for Consumers

Common use cases for Consumers:

|Use case | Description|
|---------|------------|
| Authentication | Client authentication is the most common reason for setting up a Consumer. If you're using an authentication plugin, you'll need a Consumer with credentials. |
| Rate limiting | Rate limit specific Consumers based on tiers. |
| Transformation | Add or remove values from response bodies based on the Consumer. |

## Centrally-managed Consumers 

Consumers can be scoped to a {{site.konnect_short_name}} region and managed centrally, or be scoped to a control plane in Gateway Manager.

Centralized Consumer management provides the following benefits:
* Set up a Consumer identity centrally instead of defining it in multiple control planes.
* Share Consumers across multiple control planes. Users don't need to replicate changes to Consumer identity in multiple control planes and Consumer configuration doesn't conflict.
* Reduce configuration sync issues between the control plane and the data planes. Consumers that are managed centrally aren't part of the configuration that is pushed down from the control plane to the data planes, so it reduces config size and latency. 

You can manage consumers centrally using the {{site.konnect_short_name}} API. Only Org Admins and Control Plane Admins have CRUD permissions for these consumers. When you create a Consumer centrally, you must assign it to a realm. A realm groups Consumes around an identity, defined by organizational boundaries, such as a production realm or a development realm. Realms are connected to a [geographic region](/konnect/geo/) in {{site.konnect_short_name}}. Centrally managed Consumers exist outside of control planes, so they can be used across control planes.

For a complete tutorial, see [Create a centrally-managed Consumer in {{site.konnect_short_name}}](/how-to/create-centrally-managed-consumer/).

{:.info}
> **Note:** If you are using KIC to manage your data plane nodes in {{site.konnect_short_name}}, ensure that you configure the `telemetry_endpoint` in the data plane. You can find the `telemetry_endpoint` in the {{site.konnect_short_name}} UI in [Gateway Manager](https://cloud.konghq.com/gateway-manager/) in the data plane node instructions.

## Schema

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
