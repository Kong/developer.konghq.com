---
title: Key Auth

name: Key Auth
publisher: kong-inc
content_type: plugin
description: Secure services and routes with key authentication
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
---

## Overview

This plugin lets you add API key authentication to a service or a route. Consumers then add their API key either in a query string parameter, a header, or a request body to authenticate their requests.

This plugin also comes in an enterprise version: Key Authentication Encrypted, which provides the ability to encrypt keys. Keys are encrypted at rest in the API gateway datastore.
