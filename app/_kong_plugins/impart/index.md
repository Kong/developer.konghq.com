---
title: 'Impart Security'
name: 'Impart Security'

content_type: plugin

publisher: impart-security
description: "Integrate Impart Security's WAF and API security protection platform with {{site.base_gateway}}."

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true

support_url: https://www.impart.security/get-started

icon: impart.png

tags:
  - impart-security
  - security

search_aliases:
  - kong-plugin-impart

related_resources:
  - text: Impart Kong documentation
    url: https://docs.impartsecurity.net/docs/Quickstart/Integrations/Kong_lua
---

Impart's API Protection and WAF platform delivers comprehensive protection for APIs, microservices, and serverless applications in cloud-native environments.

Use the Impart plugin to:
* Discover and catalog your API and web application Attack Surface.
* Protect your APIs and web applications from injection, enumeration, automated threats, and other attacks.
* Find and help you fix your API and web application vulnerabilities and misconfigurations with built-in API testing.
* Reduce your API and web application risk profile.

You must install the Impart Inspector for this plugin to work. 
Navigate to the Impart console for [step-by-step instructions](https://console.impartsecurity.net/orgs/_/integrations?q=kong).

## How the Impart plugin works

The Impart Kong plugin allows Impart to inspect your HTTP traffic within your own environment to detect threats, anomalies, and other interesting insights. These insights are used to protect your APIs in real time through an integration with {{site.base_gateway}} that introduces minimal additional latency, fails open to ensure reliability, and keeps sensitive data within your own environment to protect your privacy.

## Install the Impart plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-plugin-impart" %}
