---
title: 'Key Authentication - Encrypted'
name: 'Key Authentication - Encrypted'

content_type: plugin
tier: enterprise
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
  - text: Keyring
    url: /gateway/keyring/

search_aliases:
  - key auth encrypted
  - key authentication encrypted
  - key auth advanced
  - key authentication advanced
  - key-auth-enc


notes: |
  This plugin is not available in Konnect.
  Konnect automatically encrypts key authentication credentials at rest, so
  encryption via this plugin is not necessary.
  Use the regular [Key Auth](/plugins/key-auth/) plugin for API key authentication instead.

min_version:
  gateway: '1.0'
---

The Key Authentication Encrypted plugin adds encrypted API key authentication to a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/).  
[Consumers](/gateway/entities/consumer/) can authenticate by including their API key in a query string, header, or request body.

This plugin extends the functionality of the [Key Authentication](/plugins/key-auth/) plugin by allowing API keys to be stored in encrypted form within the {{site.base_gateway}} datastore.

{:.warning}
> **Important**: Before configuring this plugin, you must [enable {{site.base_gateway}}'s encryption Keyring](/gateway/keyring/#enable-keyring). 

{:.info}
> {{ page.notes }}

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