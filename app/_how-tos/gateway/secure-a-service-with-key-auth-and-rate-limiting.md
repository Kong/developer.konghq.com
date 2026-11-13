---
title: Secure a Gateway Service with key authentication and rate limiting
permalink: /how-to/secure-a-service-with-key-auth-and-rate-limiting/
content_type: how_to

description: Require an API key on a Gateway Service and limit how many requests each Consumer can send.

related_resources:
  - text: Authentication
    url: /gateway/authentication/
  - text: Key Authentication plugin
    url: /plugins/key-auth/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/

products:
    - gateway

works_on:
    - konnect

entities:
  - service
  - route
  - consumer
  - plugin

plugins:
    - key-auth
    - rate-limiting

tags:
  - authentication
  - key-auth
  - rate-limiting

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Control plane ID
      include_content: prereqs/konnect-api-for-curl
      icon_url: /assets/icons/gateway.svg

tldr:
    q: How do I require an API key and rate limit each Consumer?
    a: Enable the Key Authentication plugin on the Gateway Service, create a Consumer with an API key, then enable the Rate Limiting plugin so each Consumer gets its own limit.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

## Enable the Key Authenticaton plugin

Enable the [Key Authentication](/plugins/key-auth/) plugin on `example-service`. Requests to the Service must include a valid API key in the `apikey` header. Kong Gateway also removes the key from the request before it forwards the request to the upstream service, so your upstream never sees your credentials.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
        - apikey
{% endentity_examples %}

## Create a Consumer

[Consumers](/gateway/entities/consumer/) identify the clients that send requests through {{site.base_gateway}}. Create a Consumer named `alex`:

{% entity_examples %}
entities:
  consumers:
    - username: alex
{% endentity_examples %}

## Create an API key for the Consumer

The Consumer needs a key for the Service before it can use it, so create one for it using the {{site.konnect_short_name}} API.

Look up the ID of the `alex` Consumer:

```bash
$ CONSUMER_ID=$(curl -s "$KONNECT_CONTROL_PLANE_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/consumers" \
  -H "Authorization: Bearer $KONNECT_TOKEN" | jq -r '.data[] | select(.username == "alex") | .id')
echo $CONSUMER_ID
```

Create an API key for `alex`. {{site.konnect_short_name}} generates the key for you and returns it in the response:

```bash
curl -s -X POST "$KONNECT_CONTROL_PLANE_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/consumers/$CONSUMER_ID/key-auth" \
  -H "Authorization: Bearer $KONNECT_PAT" \
  --json '{"key": "hello_world"}'
```

You'll use this key in the validation steps below.

## Enable rate limiting for each Consumer

Enable the [Rate Limiting](/plugins/rate-limiting/) plugin on `example-service`. Each Consumer gets its own limit of 5 requests per minute — one Consumer using up its limit doesn't affect any other Consumer:

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      service: example-service
      config:
        minute: 5
        limit_by: ip
        policy: local
{% endentity_examples %}

## Validate

Send a request with the API key to confirm that key authentication is working:

{% validation request-check %}
url: /anything
headers:
  - 'apikey: hello_world'
status_code: 200
{% endvalidation %}

Wait for a minute so the rate limit counter resets. Then send requests until you reach the limit:

{% validation rate-limit-check %}
iterations: 5
url: /anything
headers:
  - 'apikey: hello_world'
{% endvalidation %}
