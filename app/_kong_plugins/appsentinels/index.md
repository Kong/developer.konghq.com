---
title: 'AppSentinels'
name: 'AppSentinels'

content_type: plugin

publisher: appsentinels
description: 'AppSentinels plugin for API security'

products:
    - gateway

works_on:
    - on-prem
    - konnect

# on_prem:
#   - hybrid
#   - db-less
#   - traditional
# konnect_deployments:
#   - hybrid
#   - cloud-gateways
#   - serverless

third_party: true

support_url: https://appsentinels.ai/

icon: appsentinels.png

min_version:
  gateway: '2.8'
---

The AppSentinels API Security Platform is purpose-built for keeping the security needs of next-generation applications in mind.
At the platform's core is an AI/ML engine, AI Sentinels, which combines multiple intelligence inputs to completely understand and baseline unique application business logic, user contexts, and intents, as well as data flow within the application, to provide the complete protection your application needs.

## How it works

The AppSentinels plugin performs logging and enforcement (blocking) of API transactions.
The plugin seamlessly integrates with {{site.base_gateway}} to provide visibility and protection.

The AppSentinels plugin works in the following modes:
* [**Logging or transparent mode**](/plugins/appsentinels/examples/logging-transparent-mode/): 
A copy of the request and response transactions is made and asynchronously shared with AppSentinels Edge Controller to provide visibility and security. 
Integrations can help provide enforcement, such as blocking of bad IPs and threat actors.
* [**Enforcement mode**](/plugins/appsentinels/examples/authz-enforcement-mode/): 
This mode provides transaction-level blocking. Incoming requests are held until the AppSentinels Edge Controller provides a verdict.
If the Controller provides a negative enforcement response, the request is dropped from further processing.
In case of higher latency of a verdict, the plugin performs a fail open to ensure business continuity.

## Install the AppSentinels plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug distributor='private' publisher="AppSentinels" %}
