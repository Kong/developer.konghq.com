---
title: "{{site.base_gateway}} control plane and data plane communication"
content_type: reference
layout: reference

products:
    - gateway

works_on:
   - on-prem
   - konnect

min_version:
    gateway: '3.5'

description: placeholder

related_resources:
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxying/
  - text: "{{site.base_gateway}} networking"
    url: /gateway/network/
  - text: "{{site.base_gateway}} ports"
    url: /gateway/network-ports-firewall/
---

@todo

Contains info from:
* https://docs.konghq.com/konnect/gateway-manager/data-plane-nodes/secure-communications/

## Use a forward proxy to secure communication between the control plane and data plane across a firewall

If your control plane and data planes are separated by a firewall that routes external communications through a proxy, you can configure {{site.base_gateway}} to authenticate with the proxy server and allow traffic to pass through.

To use a forward proxy for control plane and data plane communication, you need to configure the following parameters in [`kong.conf`](/gateway/manage-kong-conf/):

{% navtabs %}
{% navtab "HTTP example" %}
```
proxy_server = http://<username>:<password>@<proxy-host>:<proxy-port>
proxy_server_tls_verify = off
cluster_use_proxy = on
```
{% endnavtab %}
{% navtab "HTTPS example" %}
```
proxy_server = https://<username>:<password>@<proxy-host>:<proxy-port>
proxy_server_tls_verify = on
cluster_use_proxy = on
lua_ssl_trusted_certificate = system | <certificate> | <path-to-cert>
```
{% endnavtab %}
{% endnavtabs %}

[Reload {{site.base_gateway}}](/how-to/restart-kong-gateway-container/) for the connection to take effect.

The following table explains what each forward proxy parameter does:

<!--vale off-->
{% kong_config_table %}
config:
  - name: proxy_server
  - name: proxy_server_tls_verify
  - name: cluster_use_proxy
  - name: lua_ssl_trusted_certificate
{% endkong_config_table %}
<!--vale on-->

