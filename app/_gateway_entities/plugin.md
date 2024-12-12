---
title: Plugins
content_type: reference
entities:
  - plugin

description: Plugins are modules that extend the functionality of Kong Gateway.

related_resources:
  - text: Plugin Hub
    url: /plugins/
  - text: Supported scopes by plugin
    url: 'https://docs.konghq.com/hub/plugins/compatibility/#scopes'
  - text: Supported topologies by plugin
    url:  'https://docs.konghq.com/hub/plugins/compatibility/'
  - text: Supported protocols for each plugin
    url:  'https://docs.konghq.com/hub/plugins/compatibility/#protocols'
  - text: Self-managed {{site.base_gateway}} license tiers
    url:  'https://docs.konghq.com/hub/plugins/license-tiers/'
  - text: Konnect pricing tiers
    url: 'https://docs.konghq.com/konnect/compatibility/#plugin-compatibility'

tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform

schema:
    api: gateway/admin-ee
    path: /schemas/Plugin

api_specs:
    - text: Gateway Admin - EE
      url: '/api/gateway/admin-ee/#/operations/list-plugin'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20Enterprise%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-EE%2Flatest%2Fkong-ee.yaml'
    - text: Gateway Admin - OSS
      url: '/api/gateway/admin-oss/#/operations/list-plugin'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20OSS%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-OSS%2Flatest%2Fkong-oss.yaml'
    - text: Konnect Control Planes Config
      url: '/api/konnect/control-planes-config/#/operations/list-plugin'
      insomnia_link: 'https://insomnia.rest/run/?label=Konnect%20Control%20Plane%20Config&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FKonnect%2Fcontrol-planes-config%2Fcontrol-planes-config.yaml'

---

## What is a plugin?

{{site.base_gateway}} is a Lua application designed to load and execute modules. These modules, called plugins, allow you to add more features to your implementation.

Kong provides a set of standard Lua plugins that get bundled with {{site.base_gateway}} and {{site.konnect_short_name}}.
The set of plugins you have access to depends on your license tier.

You can also develop custom plugins, adding your own custom functionality to {{site.base_gateway}}.

## Schema

{% entity_schema %}
