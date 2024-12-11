---
title: Dynamically rewrite simple request URLs with {{site.base_gateway}} Routes
content_type: how_to
related_resources:
  - text: Routes
    url: /gateway/entities/route/
  - text: Services
    url: /gateway/entities/service/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/
  - text: Expressions router
    url: /gateway/routing/expressions/

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
    routes:
        - example-route

entities:
  - service
  - route

tags:
  - routing
  - traffic-control

tldr:
  q: How can I divert traffic from an old URL to a new one with {{site.base_gateway}}?
  a: Set up a Gateway Service with the old URL path and create a new a Route with new path.For example, your legacy upstream endpoint may have a base URI like `/api/old/`. However, you want your publicly accessible API endpoint to now be named `/new/api`. To route the Service’s upstream endpoint to the new URL, you can set up a Service with the path `/api/old/` and a Route with the path `/new/api`.

faqs:
  - q: My URLs are more complex, such as replacing `/api/<function>/old` with `/new/api/<function>`, what should I use instead to rewrite them?
    a: You can use the [Request Transformer plugin](/hub/request-transformer/) for a complex URL rewrite or the [expressions router](/gateway/routing/expressions/) ({{site.base_gateway}} 3.0.x or later) to describe Routes or paths as patterns using regular expressions.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Set up a Service with the path to the old Upstream

In the prerequisites, you created the `example-service` and `example-route` with the `/anything` path. This path, `/anything`, is your old upstream path. You must modify your existing Service to contain the old `/anything` path. By doing it this way, traffic can continue to be routed to the old path while you enable the new path.

{% entity_examples %}
entities:
  services:
    - name: example-service
      url: http://httpbin.konghq.com/anything
      path: /anything
append_to_existing_section: true
{% endentity_examples %}

<!--figure out apphending-->

## 2. Set up a Route with the path to the new Upstream

Now you can create a Route with your new path, `/new-path`, that points to the new Upstream.

{% entity_examples %}
entities:
  routes:
    - name: new-route
      paths:
      - "/new-path"
      service:
        name: example-service
append_to_existing_section: true
{% endentity_examples %}

## 3. Apply configuration

{% include how-tos/steps/apply_config.md %}

## 4. Validate

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

This command should display a 200 status as you're redirected to the new URL.