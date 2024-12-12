---
title: Consumer Groups
content_type: reference
entities:
  - consumer_group

description: Consumer Groups let you apply common configurations to groups of Consumers, such as rate limiting policies or request and response transformation. 

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

tier: enterprise

api_specs:
    - text: Gateway Admin - EE
      url: '/api/gateway/admin-ee/#/operations/list-consumer_group'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20Enterprise%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-EE%2Flatest%2Fkong-ee.yaml'
    - text: Gateway Admin - OSS
      url: '/api/gateway/admin-oss/#/operations/list-consumer_group'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20OSS%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-OSS%2Flatest%2Fkong-oss.yaml'
    - text: Konnect Control Planes Config
      url: '/api/konnect/control-planes-config/#/operations/list-consumer_group'
      insomnia_link: 'https://insomnia.rest/run/?label=Konnect%20Control%20Plane%20Config&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FKonnect%2Fcontrol-planes-config%2Fcontrol-planes-config.yaml'

---

## What is a Consumer Group?

Consumer Groups enable the organization and categorization of [Consumers](/gateway/entities/consumer/) (users or applications) within an API ecosystem. By grouping Consumers together, you eliminate the need to manage them individually, providing a scalable, efficient approach to managing configurations.

With Consumer Groups, you can scope plugins to specifically defined Consumer Groups and a new plugin instance will be created for each individual Consumer Group, making configurations and customizations more flexible and convenient.
For all plugins available on the consumer groups scope, see the [Plugin Scopes Reference](/hub/plugins/compatibility/#scopes).

{:.note}
> **Note**: Consumer groups plugin scoping is a feature that was added in {{site.base_gateway}} version 3.4. Running a mixed-version {{site.base_gateway}} cluster (3.4 control plane, and <=3.3 data planes) is not supported when using consumer-group scoped plugins. 

## Use cases

Common use cases for Consumer Groups:

Use case | Description
---------|------------
Managing permissions | Consumer Groups can be used to define different sets of users with varying levels of permissions. For example, you can create distinct Consumer Groups for regular users, premium users, and administrators.
Managing roles | Within an organization, there may be various departments or teams that interact with APIs differently. By creating Consumer Groups for these different roles, you can customize the API usage experience. For instance, an organization could have separate Consumer Groups for the marketing team, development team, and support team.
Resource quotas and rate limiting | Consumer Groups can be used to enforce resource quotas and rate limiting on different sets of Consumers. For instance, you can apply different rate limits to different Consumer Groups based on their subscription plans.
Customizing plugin configurations | With the ability to scope plugins specifically to defined groups, different Consumer Groups can have distinct plugin configurations based on their requirements. For example, one group may require additional request transformations while another may not need them at all.

## Schema

{% entity_schema %}

## Set up a Consumer Group

{% entity_example %}
type: consumer_group
data:
    name: my_group
{% endentity_example %}
