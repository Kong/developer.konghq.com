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

| Port | Protocol | `kong.conf` setting | Description | 
|---------|---------|------------|------------|
| `8002` | HTTP     | [`admin_gui_listen`](/gateway/configuration/#admin_gui_listen) | Kong Manager (GUI). Listens for HTTP traffic. | 
| `8445` | HTTPS    | [`admin_gui_listen`](/gateway/configuration/#admin_gui_listen) | Kong Manager (GUI). Listens for HTTPS traffic. | 
| `8005` | TCP     | [`cluster_listen`](/gateway/configuration/#cluster_listen) | Hybrid mode only. Control plane listens for traffic from data plane nodes. | 
| `8006` | TCP     | [`cluster_telemetry_listen`](/gateway/configuration/#cluster_telemetry_listen) | Hybrid mode only. Control plane listens for Vitals telemetry data from data plane nodes. | 

{% if_version gte: 3.6 %}
| `8007` | HTTP     | [`status_listen`](/gateway/configuration/#status_listen) | Status listener. Listens for calls from monitoring clients over HTTP. | 
{% endif_version %}
