---
title: Consumers
related_resources:
  - text: Authentication reference
    url: https://docs.konghq.com/gateway/latest/kong-plugins/authentication/reference/
  - text: Consumers API reference - {{site.base_gateway}}
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/#/Consumers
  - text: Consumers API reference - {{site.konnect_short_name}}
    url: https://docs.konghq.com/konnect/api/control-plane-configuration/latest/#/Consumers
  - text: Consumer groups API reference
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/#/consumer_groups
  - text: Plugins that can be enabled on consumers
    url: https://docs.konghq.com/hub/plugins/compatibility/#scopes

faqs:
  - q: What are credentials, and why do I need them?
    a: |
      Credentials are necessary to authenticate consumers via various authentication mechanisms.
      The credential type depends on which authentication plugin you want to use.
      <br><br>
      For example, a Key Authentication plugin requires an API key, and a Basic Auth plugin requires a username and password pair.

  - q: What is the difference between consumers and applications?
    a: |
      Applications provide developers the ability to get access to APIs managed by {{site.base_gateway}} or {{site.konnect_short_name}}
      with no interaction from the Kong admin team to generate credentials required.
      <br><br>
      With consumers, the Kong team creates consumers, generates credentials and needs to share them with the developers that need access to the APIs.
      You can think as applications as a type of consumer in Kong that allows developers to automatically obtain credentials for and subscribe to the required APIs.

  - q: What is the difference between consumers and developers?
    a: |
      Developers are real users of the Dev Portal, whereas consumers are abstractions.

  - q: What is the difference between consumers and RBAC users?
    a: |
      RBAC users are users of Kong Manager, whereas consumers are users (real or abstract) of the Gateway itself.

  - q: Which plugins can be scoped to consumers?
    a: |
      Certain plugins can be scoped to consumers (as opposed to services, routes, or globally). For example, you might want to
      configure the Rate Limiting plugin to rate limit a specific consumer, or use the Request Transformer plugin to edit requests for that consumer.
      You can see the full list in the <a href="https://docs.konghq.com/hub/plugins/compatibility/#scopes">plugin scopes compatibility reference</a>.

  - q: Can you scope authentication plugins to consumers?
    a: |
      No. You can associate consumers with an auth plugin by configuring credentials - a consumer with basic
      auth credentials will use the Basic Auth plugin, for example.
      But that plugin must be scoped to either a route, service, or globally, so that the consumer can access it.

  - q: Are consumers used in Kuma/Mesh?
    a: No.

  - q: Can you manage consumers with decK?
    a: |
      Yes, you can manage consumers using decK, but take caution if you have a large number of consumers.
      <br><br>
      If you have many consumers in your database, don't export or manage them using decK.
      decK is built for managing entity configuration. It is not meant for end user data,
      which can easily grow into hundreds of thousands or millions of records.
---

## What is a consumer?

A consumer typically refers to an entity that consumes or uses the APIs managed by {{site.base_gateway}}. 
Consumers can be applications, services, or users who interact with your APIs. 
Since they are not always human, {{site.base_gateway}} calls them consumers, because they "consume" the service.
{{site.base_gateway}} allows you to define and manage consumers, apply access control policies, and monitor their API usage.

Consumers are essential for controlling access to your APIs, tracking usage, and ensuring security.
They are identified by key authentication, OAuth, or other authentication and authorization mechanisms. 
For example, adding a Basic Auth plugin to a service or route allows it to identify a consumer, or block access if credentials are invalid.

You can choose to use {{site.base_gateway}} as the primary datastore for consumers, or you can map the consumer list 
to an existing database to keep consistency between {{site.base_gateway}} and your existing primary datastore.

By attaching a plugin directly to a consumer, you can manage specific controls at the consumer level, such as rate limits.

{% mermaid %}
flowchart LR

A(Consumer entity)
B(Auth plugin)
C[Upstream service]

Client --> A
subgraph id1[{{ site.base_gateway }}]
direction LR
A--Credentials-->B
end

B-->C
{% endmermaid %}

## Use cases for consumers

The following are examples of common use cases for consumers:

|Use case | Description|
|---------|------------|
|Authentication | Client authentication is the most common reason for setting up a consumer. If you're using an authentication plugin, you'll need a consumer with credentials.|
|Consumer groups | Group consumers by sets of criteria and apply certain rules to them.|
|Rate limiting | Rate limit specific consumers based on tiers.|

{% contentfor manage_entity %}
{% entity_example %}
type: consumer
data:
  custom_id: example-consumer-id
  username: example-consumer
  tags:
    - silver-tier

formats:
  - admin-api
  - konnect
  - kic
  - deck
  - ui
{% endentity_example %}
{% endcontentfor %}
