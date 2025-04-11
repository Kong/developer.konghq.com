---
title: 'Key Authentication - Encrypted'
name: 'Key Authentication - Encrypted'

content_type: plugin

publisher: kong-inc
description: 'Add key authentication to your services'


products:
    - gateway

works_on:
    - on-prem

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional

icon: key-auth-enc.png

categories:
  - authentication

related_resources:
  - text: Key Authentication plugin
    url: /plugins/key-auth/
  - text: Enable key authentication on a Gateway Service with {{site.base_gateway}}
    url: /how-to/authenticate-consumers-with-key-auth-enc/

search_aliases:
  - key auth encrypted
  - key authentication encrypted
  - key auth advanced
  - key authentication advanced
  - key-auth-enc
---

The Key Authentication Encrypted plugin lets you add API encrypted key authentication to a [Gateway Service](/gateway/entities/service/) or a [Route](/gateway/entities/route/).
[Consumers](/gateway/entities/consumer/) then add their key either in a query string parameter, a header, or a request body to authenticate their requests.

This plugin provides more functionality than the 
[Key Authentication](/plugins/key-auth/) plugin, 
letting you store API keys in an encrypted format in the {{site.base_gateway}} datastore.

{:.warning}
> **Important**: Before configuring this plugin, you must [enable {{site.base_gateway}}'s encryption Keyring](/gateway/keyring/#enable-keyring). 

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