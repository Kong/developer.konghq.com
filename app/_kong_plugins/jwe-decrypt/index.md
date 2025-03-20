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

The Kong JWE Decrypt plugin makes it possible to decrypt an inbound token (JWE) in a request.

## Supported Content Encryption Algorithms
This plugin supports the following encryption algorithms:

* A128GCM
* A192GCM
* A256GCM
* A128CBC-HS256
* A192CBC-HS384
* A256CBC-HS512

## Failure modes

The table below outlines how the plugin behaves when encountering errors: 

| Condition                | Proxied to upstream service? | Response code |
| --------                       | ---------------------------- |--------------------- |
| Has no JWE with `strict=true`   | No                           | 403                  |
| Has no JWE with `strict=false`   | Yes                          | x                    |
| Failed to decode JWE           | No                           | 400                  |
| Failed to decode JWE           | No                           | 400                  |
| Missing mandatory header values| No                           | 400                  |
| References key-set not found   | No                           | 403                  |
| Failed to decrypt              | No                           | 403                  |
