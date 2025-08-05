---
title: 'LDAP Authentication'
name: 'LDAP Authentication'

content_type: plugin

publisher: kong-inc
description: 'Integrate Kong with an LDAP server'


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
icon: ldap-auth.png

categories:
  - authentication

search_aliases:
  - ldap-auth

related_resources:
  - text: LDAP Authentication Advanced
    url: /plugins/ldap-auth-advanced/
  
min_version:
  gateway: '1.0'
---

{% include /plugins/ldap/description.md %}

For more advanced features, see the [LDAP Authentication Advanced plugin](/plugins/ldap-auth-advanced).

## Usage

{% include /plugins/ldap/usage.md %}

### Upstream headers

{% include_cached /plugins/upstream-headers.md %}

### Using service directory mapping on the CLI

{% include /plugins/ldap/service-directory-mapping.md %}

