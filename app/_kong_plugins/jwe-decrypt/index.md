---
title: 'JWE Decrypt'
name: 'JWE Decrypt'

content_type: plugin

publisher: kong-inc
description: 'Decrypt a JWE token in a request'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: jwe-decrypt.png

categories:
  - authentication

search_aliases:
  - jwe-decrypt
---

The JWE Decrypt plugin makes it possible to decrypt an inbound token (JWE) in a request.

## Supported content encryption algorithms
This plugin supports the following encryption algorithms:

* {% new_in 3.10 %} A128GCM
* {% new_in 3.10 %} A192GCM
* A256GCM
* {% new_in 3.10 %} A128CBC-HS256
* {% new_in 3.10 %} A192CBC-HS384
* {% new_in 3.10 %} A256CBC-HS512

## Failure modes

The following tables outlines how the JWE plugin behaves when encountering errors: 

{% table %}
columns:
  - title: Condition
    key: condition
  - title: "Proxied to upstream service?"
    key: proxy
  - title: Response code
    key: response
rows:
  - condition: "Has no JWE with `strict=true`"
    proxy: No
    response: 403
  - condition: Has no JWE with `strict=false`
    proxy: Yes
    response: x
  - condition: "Failed to decode JWE"
    proxy: No
    response: 400
  - condition: "Missing mandatory header values"
    proxy: No
    response: 400
  - condition: "References key-set not found"
    proxy: No
    response: 403
  - condition: "Failed to decrypt"
    proxy: No
    response: 403
{% endtable %}
