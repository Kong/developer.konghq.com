---
title: Rate limit a Gateway Service with {{site.base_gateway}}
content_type: how_to

related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
  - text: How to create rate limiting tiers with {{site.base_gateway}}
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - rate-limiting

entities: 
  - service
  - plugin

tags:
    - rate-limiting

tldr:
    q: How do I rate limit a Gateway Service with {{site.base_gateway}}?
    a: Install the <a href="/plugins/rate-limiting/">Rate Limiting plugin</a> and enable it on the <a href="/gateway/entities/service/">Service</a>.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Enable rate limiting

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the Service. 
In this example, the limit is 5 requests per second and 1000 requests per hour.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      service: example-service
      config:
        second: 5
        hour: 1000
{% endentity_examples %}

## 2. Apply configuration

{% include how-tos/steps/apply_config.md %}

## 3. Validate

After configuring the Rate Limiting plugin, you can verify that it was configured correctly and is working, by sending more requests than allowed in the configured time limit.

```bash
for _ in {1..6}
do
  curl -i http://localhost:8000/anything
done
```
{: data-deployment-topology="on-prem" }

```bash
for _ in {1..6}
do
  curl $KONNECT_PROXY_URL/example-route/anything/
done
```
{: data-deployment-topology="konnect" }

After the 5th request, you should receive the following `429` error:

```bash
{ "message": "API rate limit exceeded" }
```
