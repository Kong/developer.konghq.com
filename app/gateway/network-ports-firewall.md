---
title: Network, ports, and firewall for {{site.base_gateway}}
content_type: reference
layout: reference

products:
    - gateway

min_version:
  gateway: '3.6'

description: placeholder

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
---

<!--Original doc:
http://docs.konghq.com/gateway/latest/production/networking/firewall/
https://docs.konghq.com/gateway/latest/production/networking/default-ports/-->

Intro sentence.

what are the ports used for?

5 W + 1 H

Want something more than the defaults or want to change a default?

- proxy_listen: https://docs.konghq.com/gateway/3.9.x/reference/configuration/#proxy_listen
- admin_listen: https://docs.konghq.com/gateway/3.9.x/reference/configuration/#admin_listen
- stream_listen: https://docs.konghq.com/gateway/3.9.x/reference/configuration/#stream_listen

## Default ports

By default, {{site.base_gateway}} listens on the following ports:

| Port                                                                               | Protocol | Description | 
|-----------------------------------------------------------------------------------|---------|------------|
| `8000` | HTTP     | Takes incoming HTTP traffic from [Consumers](/gateway/entities/consumer/), and forwards it to upstream [Gateway Services](/gateway/entities/service/). | 
| `8443` | HTTPS    | Takes incoming HTTPS traffic from [Consumers](/gateway/entities/consumer/), and forwards it to upstream [Gateway Services](/gateway/entities/service/). | 
| `8001` | HTTP     | Admin API. Listens for calls from the command line over HTTP. | 
| `8444` | HTTPS    | Admin API. Listens for calls from the command line over HTTPS. | 
| `8002` | HTTP     | Kong Manager (GUI). Listens for HTTP traffic. | 
| `8445` | HTTPS    | Kong Manager (GUI). Listens for HTTPS traffic. | 
| `8005` | TCP     | Hybrid mode only. Control Plane listens for traffic from Data Planes. | 
| `8006` | TCP     | Hybrid mode only. Control Plane listens for Vitals telemetry data from Data Planes. | 
| `8007` | HTTP     | Status listener. Listens for calls from monitoring clients over HTTP. | 
