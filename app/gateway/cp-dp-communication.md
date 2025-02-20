---
title: "{{site.base_gateway}} control plane and data plane communication"
content_type: reference
layout: reference

products:
    - gateway

min_version:
    gateway: '3.5'

description: placeholder

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
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

* `proxy_server`: Proxy server defined as a URL. {{site.base_gateway}} will
only use this option if any component is explicitly configured to use the proxy.

* `proxy_server_tls_verify`: Toggles server certificate verification if
`proxy_server` is in HTTPS. Set to `on` if using HTTPS (default), or `off` if
using HTTP.

* `cluster_use_proxy`: Tells the cluster to use HTTP CONNECT proxy support for
hybrid mode connections. If turned on, {{site.base_gateway}} will use the
URL defined in `proxy_server` to connect.

* `lua_ssl_trusted_certificate` (*Optional*): If using HTTPS, you can also
specify a custom certificate authority with `lua_ssl_trusted_certificate`. If
using the [system default CA](/gateway/{{page.release}}/reference/configuration/#lua_ssl_trusted_certificate),
you don't need to change this value.

[Reload {{site.base_gateway}}](/how-to/restart-kong-gateway-container/) for the connection to take effect.

