---
title: Consumers
content_type: reference
entities:
  - consumer # we could use this to pull the schema too

description: A Consumer typically refers to an entity that consumes or uses the APIs managed by {{site.base_gateway}}.

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /authentication/
  - text: Consumer Groups API reference
    url: /api/gateway/admin-ee/#/operations/get-consumer_groups
  - text: Plugins that can be enabled on Consumers
    url: /plugins/scopes/

faqs:
  - q: What are credentials, and why do I need them?
    a: |
      Credentials are necessary to authenticate Consumers via various authentication mechanisms.
      The credential type depends on which authentication plugin you want to use.
      <br><br>
      For example, a Key Authentication plugin requires an API key, and a Basic Authentication plugin requires a username and password pair.

  - q: What is the difference between Consumers and Applications?
    a: |
      Applications provide developers the ability to get access to APIs managed by {{site.base_gateway}} or {{site.konnect_short_name}}
      with no interaction from the Kong admin team to generate the required credentials.
      <br><br>
      With Consumers, the Kong team creates Consumers, generates credentials, and shares them with the developers that need access to the APIs.
      You can think of Applications as a type of Consumer in Kong that allows developers to automatically obtain credentials for, and subscribe to the required APIs.

  - q: What is the difference between Consumers and Developers?
    a: |
      Developers are real users of the Dev Portal, whereas Consumers are abstractions.

  - q: What is the difference between Consumers and RBAC Users?
    a: |
      RBAC Users are users of Kong Manager, whereas Consumers are users (real or abstract) of the Gateway itself.

  - q: Which plugins can be scoped to Consumers?
    a: |
      Certain plugins can be scoped to Consumers (as opposed to Gateway Services, Routes, Consumer Groups, or globally). For example, you might want to
      configure the Rate Limiting plugin to rate limit a specific Consumer, or use the Request Transformer plugin to edit requests for that Consumer.
      You can see the full list in the [plugin scopes compatibility reference](/plugins/scopes/).

  - q: Can you scope authentication plugins to Consumers?
    a: |
      No. You can associate Consumers with an auth plugin by configuring credentials. For example, a Consumer with basic
      auth credentials will use the Basic Authentication plugin.
      But that plugin must be scoped to either a Route, Service, or globally, so that the Consumer can access it.


  - q: Can you manage Consumers with decK?
    a: |
      Yes, you can manage Consumers using decK, but take caution if you have a large number of Consumers.
      <br><br>
      If you have many Consumers in your database, don't export or manage them using decK.
      decK is built for managing entity configuration. It is not meant for end user data,
      which can easily grow into hundreds of thousands or millions of records.

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

api_specs:
    - gateway/admin-oss
    - gateway/admin-ee
    - konnect/control-planes-config

schema:
    api: gateway/admin-ee
    path: /schemas/Consumer
---

## What is a Consumer?

{{ page.description | liquify }} Consumers can be applications, services, or users who interact with your APIs.
Since they are not always human, {{site.base_gateway}} calls them Consumers, because they "consume" the service.
{{site.base_gateway}} allows you to define and manage Consumers, apply access control policies, and monitor their API usage.

Consumers are essential for controlling access to your APIs, tracking usage, and ensuring security.
They are identified by key authentication, OAuth, or other authentication and authorization mechanisms. 
For example, adding a Basic Auth plugin to a Gateway Service or Route allows it to identify a Consumer, or block access if credentials are invalid.

You can choose to use {{site.base_gateway}} as the primary datastore for Consumers, or you can map the Consumer list 
to an existing database to keep consistency between {{site.base_gateway}} and your existing primary datastore.

By attaching a plugin directly to a Consumer, you can manage specific controls at the Consumer level, such as rate limits.

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

## Use cases for Consumers

Common use cases for Consumers:

|Use case | Description|
|---------|------------|
|Authentication | Client authentication is the most common reason for setting up a Consumer. If you're using an authentication plugin, you'll need a Consumer with credentials.|
|Consumer Groups | Group Consumers by sets of criteria and apply certain rules to them.|
|Rate limiting | Rate limit specific Consumers based on tiers.|

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
