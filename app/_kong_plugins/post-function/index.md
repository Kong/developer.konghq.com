---
title: 'Kong Functions (Post-Plugin)'
name: 'Post-Function'

content_type: plugin

publisher: kong-inc
description: 'Add and manage custom Lua functions to execute after other plugins'


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
icon: post-function.png

categories:
  - serverless

search_aliases:
  - post-function
  - serverless function
  - serverless functions

tags:
  - serverless

related_resources:
  - text: Adjust header names in a request
    url: /how-to/adjust-header-names-in-request/
  - text: Pre-Function plugin
    url: /plugins/pre-function/

min_version:
  gateway: '1.0'
---

The Post-Function plugin (also known as Kong Functions, Post-Plugin) lets you dynamically run Lua code from {{site.base_gateway}} **after** other plugins in succession.

This plugin is part of a pair of serverless plugins. 
If you need to run Lua code _before_ other plugins in each phase, see the [Pre-Function](/plugins/pre-function/) plugin.

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