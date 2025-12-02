---
title: Apply Rate Limiting
description: Add rate limiting policies to a service or route using the `KongPlugin` CRD.
content_type: how_to
permalink: /operator/konnect/get-started/rate-limiting/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-konnectcrds-get-started
  position: 5

tldr:
  q: How do I configure rate limiting with {{site.konnect_short_name}} CRDs?
  a: |
    Use the `KongPlugin` resource to attach the `rate-limiting` plugin to a service or route.

products:
  - operator

tools:
  - operator

works_on:
  - konnect

entities: []

---

## About rate limiting

Rate limiting is used to control the rate of requests sent to an upstream service. It can be used to prevent DoS attacks, limit web scraping, and other forms of overuse. Without rate limiting, clients have unlimited access to your upstream services, which may negatively impact availability.

{{site.base_gateway}} imposes rate limits on clients through the [Rate Limiting plugin](/plugins/rate-limiting/). When rate limiting is enabled, clients are restricted in the number of requests that can be made in a configurable period of time. The plugin supports identifying clients as consumers based on authentication or by the client IP address of the requests.

{:.info}
> This tutorial uses the [Rate Limiting](/plugins/rate-limiting/) plugin. The [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin is also available. The advanced version provides additional features such as support for the sliding window algorithm and advanced Redis support for greater performance.

## Create a new `KongPlugin`

The `KongPlugin` resource lets you configure and attach plugins like `rate-limiting` to services or routes in {{site.konnect_short_name}}.

The following example enables rate limiting on a route with the following settings:

- 5 requests per minute
- Shared across consumers (no per-consumer limits)

<!-- vale off -->
{% entity_example %}
type: plugin
cluster_plugin: false
data:
  name: rate-limiting
  plugin: rate-limiting
  config:
    minute: 5
    policy: local

  kongroute: route
{% endentity_example %}
<!-- vale on -->

## Deploy a Data Plane

Apply a `DataPlane` resource to deploy a {{site.base_gateway}} instance that connects to your {{site.konnect_short_name}} Control Plane:

```bash
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane-example
  namespace: kong
spec:
  extensions:
  - kind: KonnectExtension
    name: my-konnect-config
    group: konnect.konghq.com
  deployment:
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
' | kubectl apply -f -
```

## Get the Proxy IP

Retrieve the external IP address of the deployed Data Plane service:



```bash
NAME=$(kubectl get -o yaml -n kong service | yq '.items[].metadata.name | select(contains("dataplane-ingress"))')
export PROXY_IP=$(kubectl get svc -n kong $NAME -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
curl -i $PROXY_IP
```


## Validation

After the plugin is applied, try sending more than 5 requests in a single minute to `echo-route`. You should begin receiving `429 Too Many Requests` responses once the limit is exceeded.

To test the rate-limiting plugin, rapidly send six requests to `$PROXY_IP/anything`:

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
