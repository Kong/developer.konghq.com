---
title: Rate limit a consumer with {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: How to create rate limiting tiers with {{site.base_gateway}}
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
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
  - key-auth

entities: 
  - service
  - plugin
  - consumer

tags:
    - rate-limiting

tldr:
    q: How do I rate limit a Consumer with {{site.base_gateway}}?
    a: Enable an authentication plugin and create a <a href="/gateway/entities/consumer/">Consumer</a> with credentials, then enable the <a href="/plugins/rate-limiting/">Rate Limiting plugin</a> on the new Consumer.

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

## 1. Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.
We're going to use key [authentication](/authentication/) in this tutorial, so the Consumer needs an API key to access any {{site.base_gateway}} Services.

Add the following content to `kong.yaml` to create a Consumer:

{% entity_examples %}
entities:
  consumers:
    - username: jsmith
      keyauth_credentials:
        - key: example-key
{% endentity_examples %}

## 2. Enable authentication

Authentication lets you identify a Consumer so that you can apply rate limiting.
This example uses the [Key Authentication](/plugins/key-auth) plugin, but you can use any authentication plugin that you prefer.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## 3. Enable rate limiting

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the Consumer. 
In this example, the limit is 5 requests per minute and 1000 requests per hour.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      consumer: jsmith
      config:
        minute: 5
        hour: 1000
append_to_existing_section: true
{% endentity_examples %}

## 4. Apply configuration

{% include how-tos/steps/apply_config.md %}

## 5. Validate

You can run the following command to test the rate limiting as the Consumer:

```bash
for _ in {1..6}; do curl -i http://localhost:8000/anything -H 'apikey:example-key'; echo; done
```
{: data-deployment-topology="on-prem" }

```bash
for _ in {1..6}; do curl -i $KONNECT_PROXY_URL/anything -H 'apikey:example-key'; echo; done
```
{: data-deployment-topology="konnect" }

This command sends six consecutive requests to the Route. On the last one, you should get a `429` error with the message `API rate limit exceeded`.
