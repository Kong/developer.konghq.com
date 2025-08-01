---
title: 'Kong Functions (Pre-Plugins)'
name: 'Pre-Function'

content_type: plugin

publisher: kong-inc
description: 'Add and manage custom Lua functions to run before other plugins'

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
icon: pre-function.png

categories:
  - serverless

search_aliases:
  - pre-function
  - serverless function
  - serverless functions
  - lua

tags:
  - serverless

related_resources:
  - text: Apply rate limits based on peak and off-peak time with Pre-Function
    url: /how-to/rate-limit-based-on-peak-time/
  - text: Filter requests based on header names
    url: /how-to/filter-requests-based-on-header-names/
  - text: Post-Function plugin
    url: /plugins/post-function/
  - text: All serverless plugins
    url: /plugins/?category=serverless

min_version:
  gateway: '1.0'
---

The Pre-Function plugin (also known as Kong Functions, Pre-Plugin) lets
you dynamically run Lua code from {{site.base_gateway}} before other plugins in each phase.

This plugin is part of a pair of serverless plugins. 
If you need to run Lua code _after_ other plugins in each phase, see the [Post-Function](/plugins/post-function/) plugin.

{% include_cached /plugins/serverless/untrusted-lua.md %}

## Phases

{% include_cached /plugins/serverless/phases.md name=page.name %}

## Passing Lua code to the plugin

{% include_cached /plugins/serverless/passing-lua-code.md name=page.name slug=page.slug %}

## Upvalues

{% include_cached /plugins/serverless/upvalues.md %}

## Sandboxing

The provided Lua environment is sandboxed.

{% include_cached /plugins/sandbox.md %}