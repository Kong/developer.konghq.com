---
title: Rate Limiting
description: |
  Add rate limiting to an HTTPRoute or Ingress using the KongPlugin resource
content_type: how_to

permalink: /kubernetes-ingress-controller/get-started/rate-limiting/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Get Started

series:
  id: kic-get-started
  position: 3

tldr:
  q: How to I rate limit an HTTPRoute or Ingress with {{ site.kic_product_name }}?
  a: |
    Create a `KongPlugin` resource containing a `rate-limiting` configuration. Set `config.minute` to the number of requests allowed per minute.

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

prereqs:
  skip_product: true
---

## About rate limiting

Rate limiting is used to control the rate of requests sent to an upstream service. It can be used to prevent DoS attacks, limit web scraping, and other forms of overuse. Without rate limiting, clients have unlimited access to your upstream services, which may negatively impact availability.

{{site.base_gateway}} imposes rate limits on clients through the [Rate Limiting plugin](/plugins/rate-limiting/). When rate limiting is enabled, clients are restricted in the number of requests that can be made in a configurable period of time. The plugin supports identifying clients as consumers based on authentication or by the client IP address of the requests.

{:.info}
> This tutorial uses the [Rate Limiting](/plugins/rate-limiting/) plugin. The [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin is also available. The advanced version provides additional features such as support for the sliding window algorithm and advanced Redis support for greater performance.

## Create a rate-limiting KongPlugin

Configuring plugins with {{ site.kic_product_name }} is different compared to how you'd do it with {{ site.base_gateway }}. Rather than attaching a configuration directly to a service or route, you create a `KongPlugin` definition and then annotate your Kubernetes resource with the `konghq.com/plugins` annotation.

{% entity_example %}
type: plugin
data:
  name: rate-limit-5-min
  plugin: rate-limiting
  config:
    minute: 5
    policy: local
  
  route: echo
{% endentity_example %}

## Test the rate-limiting plugin

To test the rate-limiting plugin, rapidly send six requests to `$PROXY_IP/echo`:

{% validation rate-limit-check %}
iterations: 6
url: '/echo'
headers:
  - 'apikey:example-key'
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}