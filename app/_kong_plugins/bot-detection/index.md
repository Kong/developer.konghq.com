---
title: 'Bot Detection'
name: 'Bot Detection'

content_type: plugin

publisher: kong-inc
description: 'Detect and block bots or custom clients'

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

icon: bot-detection.png

categories:
  - security

search_aliases:
  - bot-detection

tags:
  - security

min_version:
  gateway: '1.0'
---

Using the Bot Detection plugin, you can protect your a Gateway Service or a Route from bots. It automatically detects [common bots](https://github.com/Kong/kong/blob/master/kong/plugins/bot-detection/rules.lua) on every request from the associated Gateway Service or Route using regex.

You can also configure custom regex patterns to either allow or deny additional bots. 

## How it works

Once the Bot Detection plugin is enabled on a Gateway Service or Route, it checks the `User-Agent` header of incoming requests. If the header matches a default common bot or any custom denied bot regex you've configured, the request is immediately blocked with a `403` response.

If the `User-Agent` header doesn't match any common or specifically denied bots, the request is processed. This also applies when a configured allowed bot matches.

## Use case

If you suspect bot traffic you can use a [logging plugin](/plugins/?category=logging) on a Gateway Service to track down unusual `User-Agent` headers in incoming requests. 

Once you've identified the offending `User-Agent` header, you can [block it using the Bot Detection plugin](/plugins/bot-detection/examples/deny/).



