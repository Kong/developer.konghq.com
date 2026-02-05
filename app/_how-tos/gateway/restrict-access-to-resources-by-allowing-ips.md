---
title: Restrict access to {{site.base_gateway}} resources by allowing specific IPs
permalink: /how-to/restrict-access-to-resources-by-allowing-ips/
content_type: how_to

products:
    - gateway

description: Enable the IP Restriction plugin to instruct {{site.base_gateway}} to only accept requests from specific IP addresses.

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - ip-restriction

entities: 
  - service
  - route
  - plugin

tags:
    - security

tldr:
    q: How do I configure {{site.base_gateway}} to only accept requests from specific IP addresses?
    a: Enable the IP Restriction plugin and list the IPs to allow in `config.allow`.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable IP restriction

Enable the [IP Restriction plugin](/plugins/ip-restriction/) globally. 
In this example, we'll allow the reserved `192.0.2.0/24` IP range:

{% entity_examples %}
entities:
  plugins:
    - name: ip-restriction
      config:
        allow:
        - 192.0.2.0/24
{% endentity_examples %}

## Validate

After configuring the IP Restriction plugin, you can verify that it was configured correctly and is working, by sending a request:

{% validation request-check %}
url: /anything
status_code: 403
{% endvalidation %}

You should get a `403 Forbidden` status with the message `IP address not allowed`.
