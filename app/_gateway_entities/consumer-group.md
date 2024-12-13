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

related_resources:
    - text: Create rate limiting tiers with {{site.base_gateway}}
      url: /how-to/add-rate-limiting-tiers-with-kong-gateway/

api_specs:
    - text: Gateway Admin - EE
      url: '/api/gateway/admin-ee/#/operations/get-consumer_groups'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20Enterprise%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-EE%2Flatest%2Fkong-ee.yaml'
    - text: Gateway Admin - OSS
      url: '/api/gateway/admin-oss/#/operations/get-consumer_groups'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20OSS%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-OSS%2Flatest%2Fkong-oss.yaml'
    - text: Konnect Control Planes Config
      url: '/api/konnect/control-planes-config/#/operations/get-consumer_groups'
      insomnia_link: 'https://insomnia.rest/run/?label=Konnect%20Control%20Plane%20Config&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FKonnect%2Fcontrol-planes-config%2Fcontrol-planes-config.yaml'

---

## What is a Consumer Group?

Consumer Groups enable the organization and categorization of [Consumers](/gateway/entities/consumer/) (users or applications) within an API ecosystem. By grouping Consumers together, you eliminate the need to manage them individually, providing a scalable, efficient approach to managing configurations.

With Consumer Groups, you can scope plugins to specifically defined Consumer Groups and a new plugin instance will be created for each individual Consumer Group, making configurations and customizations more flexible and convenient.
For all plugins available on the consumer groups scope, see the [Plugin Scopes Reference](/hub/plugins/compatibility/#scopes).

{:.note}
> **Note**: Consumer Groups plugin scoping is a feature that was added in {{site.base_gateway}} version 3.4. Running a mixed-version {{site.base_gateway}} cluster (3.4 control plane, and <=3.3 data planes) is not supported when using plugins scoped to Consumer Groups. 

For example, you could define two groups, Gold and Silver, assign different rate limits to them, then process each group using a different plugin:

<!-- vale off -->
{% mermaid %}
flowchart LR
    A((fa:fa-user Consumers 1-5))

    B(<b>Consumer Group Gold</b>
    10 requests/second

    <i>fa:fa-user Consumer 1, fa:fa-user Consumer 2, 
    fa:fa-user Consumer 5</i> )
    
    C(<b>Consumer Group Silver</b>
    5 requests/minute

    <i>fa:fa-user Consumer 3, fa:fa-user Consumer 4</i>)

    D(Rate Limiting Advanced)
    E(Request Transformer Advanced)
    F(<b>Gateway Service</b>
    QR Code Generation)
    G(<b>Gateway Service</b>
    OCR)
    H(QR Code Generation 
    service)
    I(OCR service)

    A--> B & C
    subgraph id1 [Kong Gateway]
    direction LR
    B --> D --> F
        subgraph id2 [Gold route]
        direction LR
        D
        end
    C --> E --> G
        subgraph id3 [Silver route]
        direction LR
        E
        end
    end

    F --> H
    G --> I
{% endmermaid %}
<!--vale on -->

## Use cases

Common use cases for Consumer Groups:

Use case | Description
---------|------------
Managing permissions | You can use Consumer Groups to define different sets of users with varying levels of permissions. For example, you can create distinct Consumer Groups for regular users, premium users, and administrators.
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
