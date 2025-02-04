---
title: Basic Auth

name: Basic Auth
publisher: kong-inc
content_type: plugin
description: Secure services and routes with Basic Authentication
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

icon: basic-auth.png

categories:
  - authentication

search_aliases:
  - basic-auth

faqs:
  - q: I updated my Consumer's username, why doesn't their password or basic authenication work anymore?
    a: The basic auth password credential is encrypted in the database. {{site.base_gateway}} can only get the encrypted value of password from database. When you update the username or tag, {{site.base_gateway}} overwrites the password with its encrypted value. To fix this, enter the original password when you update the username or tag of the basic auth credential.
  - q: How do I delete a Consumer credential?
    a: You can delete a specific credential by sending a `DELETE` request to `http(s)://<kong-host>:<admin-port>/consumers/<workspace>/<consumer_id_or_name>/<type of credentials>/<credentials_id_or_name>`. (this is not in the schema, should it be?)
  - q: I'm migrating from {{site.base_gateway}} to {{site.konnect_short_name}} and using `deck gateway dump`, will this also dump my basic auth credentials?
    a: No. The basic_auth credentials are stored in the database as hashed values. When you dump the configuration with deck, it will retrieve these hashed values, not the original plain-text passwords. Since there is currently no way to extract the initial plain-text values of the basic_auth credentials due to how they are stored, you will need to manually set the passwords for basic_auth after dumping the configuration or directly setting up the password in Konnect. Please note that there is an ongoing feature request to change the behavior of how basic_auth credentials are handled during migrations to make this process more seamless in the future.
---

## Overview

The [Basic Authentication](https://datatracker.ietf.org/doc/html/rfc7617 ) plugin enforces username and password authentication for Consumers when making a request to a Gateway Service or Route. Consumers represent a developer or an application consuming the service application. 

## How it works

When the Basic Authentication plugin is enabled an a consumer makes a request to a Gateway Service or Route, the plugin checks for valid credentials in the `Proxy-Authorization` and `Authorization` headers (in that order).

The Consumer's password must be base64 encoded when it's used in the Authentication header.

## Use cases

Common use cases for the Basic Authentication plugin:

| Allow or deny requests on a Gateway Service or Route | ACL + basic auth |
| Authenticate on the upstream service | Request transformer + basic auth |
| Allow clients to choose their authentication method (multiple auth methods) | Basic auth + any other auth plugin(s) |
| Check credentials per session | Session token + basic auth |
| Prevent anon access | Request termination + basic auth |
| Rate limit unauthenticated and authenticated users differently | Rate limiting + basic auth |



<!--Kong manager functions with basic auth???-->



## Related how tos

https://support.konghq.com/support/s/article/How-to-change-Kong-manager-password-from-database
