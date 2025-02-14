---
title: "{{site.base_gateway}} ports"
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
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxying/
  - text: "{{site.base_gateway}} networking"
    url: /gateway/network/
---

<!--Original doc:
http://docs.konghq.com/gateway/latest/production/networking/firewall/
https://docs.konghq.com/gateway/latest/production/networking/default-ports/
-->

{{site.base_gateway}} uses ports for the following:
* **[Proxying](/gateway/traffic-control/proxying/) incoming traffic**
  * In general, the proxy ports are the *only* ports that should be made available to your clients. Upstream services are accessible via the proxy interface and ports, so make sure that these values only grant the access level you require. See [`proxy_listen` in the Kong configuration reference](/gateway/configuration/) for more details on HTTP/HTTPS proxy listen options. 
  * You can also proxy TCP/TLS streams, which is disabled by default. If you want to proxy this traffic, see [`stream_listen` in the Kong configuration reference](/gateway/configuration/) for more information about stream proxy listen options and how to enable it.
  * Your proxy will need have rules added for any HTTP/HTTPS and TCP/TLS stream listeners that you configure. For example, if you want {{site.base_gateway}} to manage traffic on port `4242`, your firewall must allow traffic on that port.
* **Exposing the [Admin API](/api/gateway/admin-ee/)**: This is used to manage {{site.base_gateway}}. You should [prevent unauthorized access](/gateway/secure-the-admin-api/) to these ports in production. See [`admin_listen` in the Kong configuration reference](/gateway/configuration/) for more information about the configuration.

## Default ports

By default, {{site.base_gateway}} listens on the following ports:

| Port                                                                               | Protocol | Description | 
|-----------------------------------------------------------------------------------|---------|------------|
| `8000` | HTTP     | Takes incoming HTTP traffic from [Consumers](/gateway/entities/consumer/), and forwards it to upstream services. | 
| `8443` | HTTPS    | Takes incoming HTTPS traffic from [Consumers](/gateway/entities/consumer/), and forwards it to upstream services. | 
| `8001` | HTTP     | Admin API. Listens for calls from the command line over HTTP. | 
| `8444` | HTTPS    | Admin API. Listens for calls from the command line over HTTPS. | 
| `8002` | HTTP     | Kong Manager (GUI). Listens for HTTP traffic. | 
| `8445` | HTTPS    | Kong Manager (GUI). Listens for HTTPS traffic. | 
| `8005` | TCP     | Hybrid mode only. Control plane listens for traffic from data plane nodes. | 
| `8006` | TCP     | Hybrid mode only. Control plane listens for Vitals telemetry data from data plane nodes. | 
| `8007` | HTTP     | Status listener. Listens for calls from monitoring clients over HTTP. | 

