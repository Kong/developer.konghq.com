---
title: 'DataDome'
name: 'DataDome'

content_type: plugin

publisher: datadome
description: "Detect and mitigate attacks on mobile apps, websites, and APIs with DataDome bot and online fraud protection"

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true
support_url: https://docs.datadome.co/docs/support

icon: datadome.png

related_resources:
  - text: DataDome Kong documentation
    url: https://docs.datadome.co/docs/kong-plugin

min_version:
  gateway: '2.8'
---

The Kong DataDome plugin relies on the DataDome Bot & Fraud Protection Platform to validate if any incoming API request is legitimate or coming from a bot.

Once the plugin is installed, the only requirement is to configure your DataDome server-side key.

## How it works

Here's how the plugin works:
1. The DataDome plugin hooks into every API request from a client.
2. The plugin proxies a request to the DataDome Bot & Fraud Protection Platform to assess threats in real time using DataDome's machine learning solution.
3. The plugin either allows the request to be proxied to the upstream service, or rejects and blocks it based on DataDome's assessment.

## Install the DataDome plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-plugin-datadome" %}