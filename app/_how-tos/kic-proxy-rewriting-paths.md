---
title: Rewrite paths with the konghq.com/rewrite annotation
short_title: Rewriting paths
description: "Dynamically rewrite paths using regular expressions before sending requests upstream"
content_type: how_to

permalink: /kubernetes-ingress-controller/routing/rewriting-paths/

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I rewrite an incoming request path using {{ site.kic_product_name }}?
  a: Use the `konghq.com/rewrite` annotation to specify the new upstream path e.g. `konghq.com/rewrite=/users/$1`

prereqs:
  kubernetes:
    feature_gates: 'RewriteURIs=true'
  entities:
    services:
      - httpbin-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg

related_resources:
  - text: Rewriting paths
    url: /kubernetes-ingress-controller/reference/path-manipulation/
  - text: Rewriting hosts
    url: /kubernetes-ingress-controller/reference/host-manipulation/
---

## Configure a rewrite

{:.warning}
> This feature requires the [`RewriteURIs` feature gate](/kubernetes-ingress-controller/reference/feature-gates/) to be activated and only works with `Ingress` resources

{{ site.kic_product_name }} provides the `konghq.com/rewrite` annotation to customize the request path before it is sent to the upstream service.

The annotation can be used on `Ingress` and `HTTPRoute` resources, and configures a [request-transformer](/plugins/request-transformer/) plugin within {{ site.base_gateway }} when added to a Route.

The following definition creates a Route that matches the path `/external-path/(\w+)` and rewrites it to `/anything/$1` before sending the request upstream. 

{% include /k8s/httproute.md disable_gateway=true path='/external-path/(\w+)' name='httpbin' service='httpbin' port='80' skip_host=true route_type='RegularExpression' annotation_rewrite="/anything/$1" %}

Alternatively, you can define this in a plugin configuration:

{% entity_example %}
type: plugin
data:
  name: request-transformer
  config:
    replace:
      uri: "/anything/$(uri_captures[1])"
{% endentity_example %}

The `$1` in the annotation is expanded to `$(uri_captures[1])` in the plugin configuration.

Up to nine capture groups are supported using the `konghq.com/rewrite` annotation. If you need more than 9 capture groups, [create a KongPlugin resource](/hub/kong-inc/request-transformer/how-to/basic-example/?tab=kubernetes) to handle the transformation.

## Validate your configuration

To validate that your rewrite is working, make a HTTP request to `/external-path/123`:

{% validation request-check %}
url: /external-path/123
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The response contains a `url` key which shows the URL sent to the upstream service, plus an `X-Forwarded-Path` header that shows the original request path.