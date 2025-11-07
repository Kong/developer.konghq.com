---
title: Key Auth

name: Key Auth
publisher: kong-inc
content_type: plugin
description: Secure Services and Routes with key authentication
tags:
    - authentication

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: key-auth.png

categories:
  - authentication

search_aliases:
  - key authentication
  - key-auth

related_resources:
  - text: Enable key authentication on a Gateway Service with {{site.base_gateway}}
    url: /how-to/enable-key-authentication-on-a-service-with-kong-gateway/
  - text: "{{site.base_gateway}} authentication"
    url: /gateway/authentication/

notes: |
  This setting determines the length of time a credential remains valid.

min_version:
  gateway: '1.0'
---

The Key Authentication plugin lets you add API key authentication to a [Gateway Service](/gateway/entities/service/) or a [Route](/gateway/entities/route/).
[Consumers](/gateway/entities/consumer/) then add their key either in a query string parameter, a header, or a request body to authenticate their requests.

The advanced version of this plugin, [Key Authentication Encrypted](/plugins/key-auth-enc/), provides the ability to encrypt keys. Keys are encrypted at rest in the {{site.base_gateway}} data store.

## Request behavior matrix

{% include_cached /plugins/key-auth/request-behavior.md %}

## Consumer key management

{% include_cached /plugins/key-auth/consumer-keys.md slug=page.slug %}

### API key locations in a request

{% include_cached /plugins/key-auth/api-key-locations.md %}

## Case sensitivity

{% include_cached /plugins/key-auth/case-sensitivity.md %}

## Upstream headers

{% include_cached /plugins/upstream-headers.md %}

## Identity realms {% new_in 3.10 %}

You can authenticate [centrally-managed Consumers](/gateway/entities/consumer/#centrally-managed-consumers) in {{site.konnect_short_name}} by configuring the [`config.identity_realms`](./reference/#schema--config-identity-realms) field.
See [Realms for external Consumers in {{site.konnect_short_name}}](/plugins/key-auth/examples/identity-realms/) for an example configuration.

Identity realms are scoped to the Control Plane by default (`scope: cp`). 
The order in which you configure the identity realm dictates the priority in which the Data Plane attempts to authenticate the provided API keys:

{% table %}
columns:
  - title: Condition
    key: condition
  - title: Description
    key: description
rows:
  - condition: Realm is listed first
    description: |
      The Data Plane will first reach out to the realm. If the API key is not found in the realm, the Data Plane will look for the API key in the Control Plane config. 
  - condition: Control plane scope listed first
    description: |
      The Data Plane will initially check the Control Plane configuration (LMDB) for the API key before looking up the API key in the realm.
  - condition: Realm only
    description: |
      You can configure a single identity realm by removing `cp` from `config.identity_realms.scope`. In this case, the Data Plane will only attempt to authenticate API keys against the realm. 
      
      If the API key isn't found, the request will be blocked.
  - condition: Control plane only
    description: |
      You can configure a lookup only in the Control Plane config by specifying `cp` in `config.identity_realms.scope` and no other identity realm parameters. In this scenario, the Data Plane will only check the Control Plane configuration (LMDB) for API key authentication. 
      
      If the API key isn't found, the request will be blocked.
{% endtable %}