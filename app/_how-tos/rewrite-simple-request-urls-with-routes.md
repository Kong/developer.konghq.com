---
title: Rewrite simple request URLs with {{site.base_gateway}} Routes
content_type: how_to
related_resources:
  - text: Routes
    url: /gateway/entities/route/
  - text: Services
    url: /gateway/entities/service/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service

entities:
  - service
  - route

tags:
  - routing
  - traffic-control

tldr:
  q: How can I divert traffic from an old URL to a new one with {{site.base_gateway}}?
  a: Create a new route and point it to the existing Gateway Service. The new route will proxy traffic to the existing service at the new URL.

faqs:
  - q: My URLs are more complex, such as replacing `/api/<function>/old` with `/new/api/<function>`, what should I use instead to rewrite them?
    a: You can use either the [Request Transformer plugin](/hub/request-transformer/) or the [expressions router](/gateway/routing/expressions/) for complex URLs. 

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Set up a Route with the path to the new Upstream

In the prerequisites, you created the `example-service` pointing to the `/anything` upstream. This path, `/anything`, is your old upstream path. You must create a Route with your new path, `/new-path`, that points to the new Upstream. By doing it this way, traffic can continue to be routed to the old path while you enable the new path.

{% entity_examples %}
entities:
  routes:
    - name: new-route
      paths:
      - "/new-path"
      service:
        name: example-service
{% endentity_examples %}

## 2. Apply configuration

{% include how-tos/steps/apply_config.md %}

## 3. Validate

To validate that the URL was successfully rewritten and the request is now being matched to the new Upstream instead of the old one, run the following:

```bash
curl -i http://localhost:8000/new-path
```
{: data-deployment-topology="on-prem" }

```bash
curl -i http://{host}/new-path
```
{: data-deployment-topology="konnect" }
Replace `{host}` with the proxy URL for this data plane node.
{: data-deployment-topology="konnect" }

This command should display a 200 status as you're redirected to the new URL. In the response, you'll also see that `"Host": "httpbin.konghq.com",` as the request is proxied to the new URL.