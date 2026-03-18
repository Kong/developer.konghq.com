---
title: 'Metering & Billing'
name: 'Metering & Billing'

content_type: plugin

publisher: kong-inc
description: 'Meter API requests and AI token usage for usage-based billing. Supports flexible customer identification, custom pricing dimensions, and fine-grained traffic filtering. Integrates natively with {{site.konnect_short_name}} {{site.metering-and-billing}}.'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.14'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - monetization

search_aliases:
  - metering-and-billing
  - metering


icon: metering-and-billing.png # e.g. acme.svg or acme.png

categories:
   - monetization

related_resources:
  - text: How-to guide for the plugin
    url: /how-to/guide/
---

intro sentence about what it does
Kong Gateway use cases

For {{site.konnect_short_name}}, you have the option to use the built-in {{site.metering-and-billing}} event ingestion that uses events from Advanced Analytics or use the Metering & Billing plugin.

The following table can help you determine which to use based on your use case:

<!--vale off-->
{% table %}
columns:
  - title: Requirement
    key: requirement
  - title: Built-in (Advanced Analytics)
    key: builtin
  - title: Metering & Billing plugin
    key: plugin
rows:
  - requirement: Deployment
    builtin: Konnect-managed gateways only
    plugin: Konnect-managed, self-hosted, and OSS Kong Gateway
  - requirement: Setup
    builtin: Enabled with one click in Konnect
    plugin: Manual plugin configuration required
  - requirement: Subject (who gets billed)
    builtin: Consumer or application, selected implicitly
    plugin: Consumer, consumer group, application, or any request header (for example, `x-customer-id` or `x-tenant-id`)
  - requirement: Custom billing dimensions
    builtin: Not supported
    plugin: Attach any request header or query parameter as a dimension on the event (for example, department, project, priority tier)
  - requirement: Traffic filtering
    builtin: Gateway-level only; cannot exclude individual routes or services
    plugin: Use the plugin's execution condition to exclude any traffic by route, service, header, or expression
  - requirement: AI token metering
    builtin: Supported
    plugin: Supported; emits separate input and output token events for independent pricing
  - requirement: Double-counting risk
    builtin: None when used alone
    plugin: If your gateway is on Konnect and the Advanced Analytics pipeline is still active, disable it before enabling the plugin to avoid duplicate billing events
{% endtable %}
<!--vale on-->

## How it works

infos about how it works

## 