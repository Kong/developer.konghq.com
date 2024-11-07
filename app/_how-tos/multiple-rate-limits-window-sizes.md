---
title: Multiple rate limits and window sizes
content_type: how_to

related_resources:
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

products:
  - gateway

works_on:
  - on-prem
  - konnect

plugins: 
  - rate-limiting-advanced

entities:
  - service

tools:
  - deck

tier: enterprise

tags:
  - rate-limiting

prereqs:
  entities:
      services:
        - example-service
      routes:
        - example-route

tldr: 
  q: How do I apply multiple rate limits or window sizes with one plugin instance?
  a: |
    You can use the Rate Limiting Advanced plugin to apply any number of rate limits and window sizes per plugin instance. 
    This lets you create multiple rate limiting windows, for example, rate limit per minute and per hour, and per any arbitrary window size.

faqs:
  - q: Why can't I use the regular Rate Limiting plugin to set multiple limits and window sizes?
    a: You could use the regular Rate Limiting plugin to just set multiple limits, but the regular plugin doesn't support configurable window sizes.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the Kong Gateway container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## 1. Enable rate limiting

Enable the [Rate Limiting Advanced plugin](/plugins/rate-limiting-advanced/) for the service.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting-advanced
      service: example-service
      config:
        limit:
        - 10
        - 100
        window_size:
        - 60
        - 3600
{% endentity_examples %}

Each *nth* limit will apply to each *nth* window size.

This example applies rate limiting policies, one of which will trip when 10 hits have been counted in 60 seconds,
or the other when 100 hits have been counted in 3600 seconds. 

The number of configured window sizes and limits parameters must be equal (as shown above);
otherwise, an error occurs:

```plaintext
You must provide the same number of windows and limits
```

## 2. Validate

After configuring the Rate Limiting Advanced plugin, you can verify that it was configured correctly and is working, 
by sending more requests then allowed in the configured time limit.

```bash
for _ in {1..11}
do
  curl http://localhost:8000/example-route/anything/
done
```
After the 11th request in a minute, you should receive the following `429` error:

```bash
{ "message": "API rate limit exceeded" }
```
