---
title: Consumer Groups
content_type: reference
entities:
  - consumer-group

description: Consumer Groups let you apply common configurations to groups of Consumers, such as rate limiting policies or request and response transformation. 

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

related_resources:
    - text: Create rate limiting tiers with {{site.base_gateway}}
      url: /how-to/add-rate-limiting-tiers-with-kong-gateway/
    - text: Consumer entity
      url: /gateway/entities/consumer/
    - text: Plugins that can be scoped to Consumer Groups
      url: /gateway/entities/plugin/#supported-scopes-by-plugin
    - text: Reserved entity names
      url: /gateway/reserved-entity-names/
    - text: "{{site.konnect_short_name}} Control Plane resource limits"
      url: /gateway/control-plane-resource-limits/


api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

faqs:
  - q: Why aren't Consumer Group overrides working anymore?
    a: |
      Consumer Groups became a core Gateway entity in 3.4, which opened up a wide range of use cases for grouping Consumers.
      
      Before 3.4, Consumer Groups were limited to rate limiting plugins, where they were configured through overrides. This is no longer necessary. Instead, you can enable any rate limiting plugin directly on a consumer group without worrying about extra configuration.
  - q: How do I enable a plugin on a Consumer Group?
    a: |
      First, [find out](/gateway/entities/plugin/#supported-scopes-by-plugin) if the plugin you want supports Consumer Groups. 
      
      If it does, head over to the plugin's documentation, open the "Get Started" tab, and choose "Consumer Groups" from the dropdown for any available example.

  - q: When a Consumer is part of multiple Consumer Groups, how is precedence determined?
    a: |
      Currently, this is determined by the Group name, in alphabetical order. For more details, see [Plugin precedence](/gateway/entities/plugin/#plugin-precedence).

schema:
    api: gateway/admin-ee
    path: /schemas/ConsumerGroup


works_on:
  - on-prem
  - konnect
---

## What is a Consumer Group?

Consumer Groups enable the organization and categorization of [Consumers](/gateway/entities/consumer/) (users or applications) within an API ecosystem. By grouping Consumers together, you eliminate the need to manage them individually, providing a scalable, efficient approach to managing configurations.

With Consumer Groups, you can scope plugins to specifically defined Consumer Groups and a new plugin instance will be created for each individual Consumer Group, making configurations and customizations more flexible and convenient.
For all plugins available on the consumer groups scope, see the [Plugin scopes reference](/gateway/entities/plugin/#supported-scopes-by-plugin).

For example, you could define two groups, Gold and Silver, assign different rate limits to them, then process each group using a different plugin:

<!-- vale off -->
{% mermaid %}
flowchart LR
    A((fa:fa-user Consumers 1-5))

    B(<b>Consumer Group Gold</b>

    fa:fa-user Consumer 1, fa:fa-user Consumer 2, 
    fa:fa-user Consumer 5 )
    
    C(<b>Consumer Group Silver</b>

    fa:fa-user Consumer 3, fa:fa-user Consumer 4)

    D(Rate Limiting Advanced
    10 requests/second)
    E(Rate Limiting Advanced
    2 requests/second)
    F(<b>Gateway Service</b>
    QR Code Generation)
    H(QR Code Generation 
    service)

    A--> B & C
    subgraph id1 [Kong Gateway]
    direction LR
    B --> D --> F
    C --> E --> F
    end

    F --> H
{% endmermaid %}
<!--vale on -->

Without Consumer Groups, you would have to use five Rate Limiting Advanced plugins, once for each consumer. 
Any time you change the rate limit, you would need to update every consumer individually.

Consumer Groups allow you to manage your plugin configuration centrally, and reduce the size of your {{ site.base_gateway }} configuration at the same time. 
In this example, it's the difference between using two plugins or five plugins. In your production environment, it could be the difference between two plugins and five _million_ plugins.

## Use cases

Common use cases for Consumer Groups:
<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: "Managing permissions"
    description: "You can use Consumer Groups to define different sets of users with varying levels of permissions. For example, you can create distinct Consumer Groups for regular users, premium users, and administrators."
  - usecase: "Managing roles"
    description: "Within an organization, there may be various departments or teams that interact with APIs differently. By creating Consumer Groups for these different roles, you can customize the API usage experience. For instance, an organization could have separate Consumer Groups for the marketing team, development team, and support team."
  - usecase: "Resource quotas and rate limiting"
    description: "Consumer Groups can be used to enforce resource quotas and rate limiting on different sets of Consumers. For instance, you can apply different rate limits to different Consumer Groups based on their subscription plans."
  - usecase: "Customizing plugin configurations"
    description: "With the ability to scope plugins specifically to defined groups, different Consumer Groups can have distinct plugin configurations based on their requirements. For example, one group may require additional request transformations while another may not need them at all."
{% endtable %}
<!--vale on-->

## Schema

{% entity_schema %}

## Set up a Consumer Group

{% entity_example %}
type: consumer_group
data:
    name: my_group
{% endentity_example %}
