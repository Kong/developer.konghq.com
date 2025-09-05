---
title: 'Salt Security'
name: 'Salt Security'

content_type: plugin

publisher: salt
description: "Integrate Kong API Gateway with Salt Security Discovery & Prevention for API-based apps"

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true

support_url: https://salt.security/contact-us

icon: salt-agent.png

search_aliases:
  - salt-agent

tags:
  - traffic-control

min_version:
  gateway: '1.0'
---

The Salt Security Kong deployment is used to capture a mirror of application traffic and send it to the Salt Security Service for analysis.
This plugin has low CPU and memory consumption and adds no latency to the application since it doesn't sit in line with the production traffic.
The plugin needs to see unencrypted traffic (after SSL termination) to enable the Salt Security service to perform analysis.

## Install the Salt Security plugin

You can install the Salt Security plugin for {{site.base_gateway}} via Luarocks.

### Prerequisites

Obtain the plugin `.rock` file from your Salt Security distributor.

### Install

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-plugin-salt-agent-0.1.0-1.all.rock" %}
