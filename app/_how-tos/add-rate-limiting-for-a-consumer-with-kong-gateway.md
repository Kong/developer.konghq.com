---
title: Enable rate limiting for a consumer with Kong Gateway
related_resources:
  - text: How to create rate limiting tiers with Kong Gateway
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
  gateway: 3.4.x

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
    q: How do I rate limit a consumer with Kong Gateway?
    a: Make sure you have enabled an authentication plugin and created a consumer with credentials, then enable the <a href="/plugins/rate-limiting/reference">Rate Limiting plugin</a> for that consumer. 

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
    - title: Destroy the Kong Gateway container
      include_content: cleanup/products/gateway
---

## 1. Enable authentication

You need [authentication](/authentication/) to identify a consumer and apply rate limiting.
This example uses the [Key Authentication](/plugins/key-auth) plugin, but you can use any authentication plugin that you prefer.

Add the following content to `kong.yaml` to enable the plugin globally, which means it applies to all Kong Gateway services and routes:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## 2. Create a consumer

Consumers let you identify the client that's interacting with Kong Gateway. 
With the Key Authentication plugin enabled globally, the consumer needs an API key to access any Kong Gateway services.

Append the following snippet to the `kong.yaml` file to create a [consumer](/gateway/entities/consumer/) with an API key:

{% entity_examples %}
entities:
  consumers:
    - username: jsmith
      keyauth_credentials:
        - key: example-key
append_to_existing_section: true
{% endentity_examples %}

## 3. Enable rate limiting

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the consumer. 
In this example, the limit is 5 requests per second and 1000 requests per hour.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      consumer: jsmith
      config:
        second: 5
        hour: 1000
append_to_existing_section: true
{% endentity_examples %}

## 4. Apply configuration

Synchronize your [decK](/deck/) configuration files.

First, compare the decK file or files to the state of the Kong Gateway:
```bash
deck gateway diff deck_files
```
The output shows you which entities are changing. 
If everything looks right, synchronize them to update your Gateway configuration:

```bash
deck gateway sync deck_files
```

## 5. Validate

You can run the following command to test the rate limiting as the consumer:
```bash
for _ in {1..6}; do curl -i http://localhost:8000/example-route -H 'apikey:example_key'; echo; done
```

This command sends six consecutive requests to the route. On the last one you should get a `429` error with the message `API rate limit exceeded`.
