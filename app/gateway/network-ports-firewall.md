---
title: "{{site.base_gateway}} ports"
content_type: reference
layout: reference

products:
    - gateway

min_version:
  gateway: '3.4'

description: Learn which ports {{site.base_gateway}} uses and how to configure them.

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxying/
  - text: "{{site.base_gateway}} networking"
    url: /gateway/network/

works_on:
  - on-prem
---

{{site.base_gateway}} needs port access for two main types of connections: traffic passing through the proxy and managing the {{site.base_gateway}} via the Admin API.

## Proxy ports

{% include_cached /sections/data-plane-node-ports.md %}

## Admin API ports

The Admin API is used to manage {{site.base_gateway}}. You should [prevent unauthorized access](/gateway/secure-the-admin-api/) to these ports in production.

The following are the default ports used by the Admin API:

| Port | Protocol | `kong.conf` setting | Description | 
|---------|---------|------------|------------|
| `8001` | HTTP     | [`admin_listen`](/gateway/configuration/#admin_listen) | Listens for Admin API calls from the command line over HTTP. | 
| `8444` | HTTPS    | [`admin_listen`](/gateway/configuration/#admin_listen) | Listens for Admin API calls from the command line over HTTPS. | 

## Other default ports

In addition to the proxy and Admin API ports, {{site.base_gateway}} listens on the following other ports by default:

{% table %}
columns:
  - title: Port
    key: port
  - title: Protocol
    key: protocol
  - title: |
      `kong.conf` setting
    key: setting
  - title: Description
    key: description
rows:
  - port: |
     `8002`
    protocol: HTTP
    setting: |
      [`admin_gui_listen`](/gateway/configuration/#admin_gui_listen)
    description: Kong Manager (GUI). Listens for HTTP traffic.
  - port: |
     `8445`
    protocol: HTTPS
    setting: |
      [`admin_gui_listen`](/gateway/configuration/#admin_gui_listen)
    description: Kong Manager (GUI). Listens for HTTPS traffic.
  - port: |
     `8005`
    protocol: TCP
    setting: |
      [`cluster_listen`](/gateway/configuration/#cluster_listen)
    description: Hybrid mode only. Control plane listens for traffic from data plane nodes.
  - port: |
     `8006`
    protocol: TCP
    setting: |
      [`cluster_telemetry_listen`](/gateway/configuration/#cluster_telemetry_listen)
    description: Hybrid mode only. Control plane listens for Vitals telemetry data from data plane nodes.
  - port: |
     `8007`
    protocol: HTT
    setting: |
      [`status_listen`](/gateway/configuration/#status_listen)
    description: |
      {% new_in 3.6 %} Status listener. Listens for calls from monitoring clients over HTTP.
{% endtable %}
