---
title: HTTP proxy configuration
description: "Configure {{site.operator_product_name}} to route outbound traffic through an HTTP proxy using standard Go environment variables."
content_type: reference
layout: reference
breadcrumbs:
  - /operator/
  - index: operator
    group: Reference

products:
  - operator

works_on:
  - on-prem
  - konnect
---

{{ site.operator_product_name }} is built with Go and respects the standard proxy environment variables defined by Go's [`ProxyFromEnvironment`](https://pkg.go.dev/net/http#ProxyFromEnvironment).
This allows you to route the {{ site.operator_product_name_short }}'s outbound HTTP(S) traffic through a corporate proxy or forward proxy.

## Supported environment variables

Use the following environment variables to configure the proxying:

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Description
    key: description
rows:
  - variable: '`HTTP_PROXY`'
    description: "Proxy URL to use for outbound HTTP requests."
  - variable: '`HTTPS_PROXY`'
    description: "Proxy URL to use for outbound HTTPS requests."
  - variable: '`NO_PROXY`'
    description: "Comma-separated list of hosts, IP addresses, or CIDR ranges that should bypass the proxy."
{% endtable %}

The lowercase variants (`http_proxy`, `https_proxy`, `no_proxy`) are also supported.
If both uppercase and lowercase variants are set, the uppercase variant takes precedence.

## `NO_PROXY` format

The `NO_PROXY` variable accepts a comma-separated list of entries. Each entry can be:

- A hostname (e.g. `example.com`) &mdash; matches that host exactly.
- A domain with a leading dot (e.g. `.example.com`) &mdash; matches the domain and all subdomains.
- An IP address (e.g. `10.0.0.1`).
- A CIDR range (e.g. `10.0.0.0/8`).
- `*` &mdash; bypasses the proxy for all requests.

## Configure proxy variables in Helm

Set the environment variables through Helm values:

```yaml
customEnv:
  HTTP_PROXY: "http://proxy.example.com:3128"
  HTTPS_PROXY: "http://proxy.example.com:3128"
  NO_PROXY: "10.0.0.0/8,127.0.0.1,localhost,.svc,.cluster.local"
```

{:.info}
> Make sure to include Kubernetes internal addresses (such as `.svc` and `.cluster.local`) in `NO_PROXY` so that in-cluster communication is not routed through the proxy.
