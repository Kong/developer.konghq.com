---
title: How to create rate limiting tiers with {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Consumer Group API documentation
    url: /api/gateway/admin-ee/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

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

min_version:
  gateway: '3.4'

plugins:
  - rate-limiting-advanced
  - key-auth

entities:
  - consumer
  - consumer_group

tier: enterprise

tags:
  - rate-limiting

tldr:
  q: How do I rate limit different tiers of users, such as free vs. premium subscribers, in my API using {{site.base_gateway}}?
  a: To effectively manage API traffic for various user tiers (such as free, basic, and premium subscribers) you can create consumer groups for each tier and assign individual consumers to these groups. Then, configure the Rate Limiting Advanced plugin to apply specific rate limits based on these groups. This setup allows you to enforce customized request limits for each tier, ensuring fair usage and optimizing performance for high-value users.

faqs:
  - q: Why can't I use the regular Rate Limiting plugin to rate limit tiers of consumers?
    a: We use the Rate Limiting Advanced plugin because it supports sliding windows, which we use to apply the rate limiting logic while taking into account previous hit rates (from the window that immediately precedes the current) using a dynamic weight.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Set up consumer authentication

We need to set up [authentication](/authentication/) to identify the consumer and apply rate limiting. In this guide, we'll be using the [Key Auth plugin](https://docs.konghq.com/hub/kong-inc/key-auth/) plugin, but you can use any [Kong authentication plugin](https://docs.konghq.com/hub/?category=authentication). 

Add the following content to your `kong.yaml` file in the `deck_files` directory to configure the Key Auth plugin:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## 2. Create consumer groups for each tier

Before you can enable rate limiting for tiers of users, we first have to create consumer groups for each tier and then add consumers to those groups. Consumer groups are solely a way to organize consumers of your APIs. In this guide, we'll create three tiers (Free, Basic, and Premium), so we need to create a unique consumer group for each tier.

Append the following content to your `kong.yaml` file in the `deck_files` directory to create consumer groups for each tier:

{% entity_examples %}
entities:
  consumer_groups:
    - name: Free
    - name: Basic
    - name: Premium
{% endentity_examples %}

## 3. Create consumers

Now that you've added consumer groups for each tier, you can create three consumers, one for each tier. Here, we're manually adding consumers for the sake of ease, but in a production environment, you could use a script that would automatically add consumers to the correct groups as they sign up for a tier of service.

We're also adding key auth credentials (`key`) to each consumer so they can authenticate and we can test later that rate limiting was correctly configured for the different tiers.

Append the following content to your `kong.yaml` file in the `deck_files` directory to create consumers and their authentication credentials:

{% entity_examples %}
entities:
  consumers:
    - username: Amal
      groups:
        - name: Free
      keyauth_credentials:
        - key: amal
    - username: Dana
      groups:
        - name: Basic
      keyauth_credentials:
        - key: dana
    - username: Mahan
      groups:
        - name: Premium
      keyauth_credentials:
        - key: mahan
{% endentity_examples %}

## 4. Enable rate limiting on each tier

Enable the Rate Limiting Advanced plugins for each tier:

{% entity_examples %}
entities:
   plugins:
   - name: rate-limiting-advanced
     consumer_group: Free
     config:
       limit: 
       - 3
       window_size: 
       - 30
       window_type: fixed
       retry_after_jitter_max: 0
       namespace: free
   - name: rate-limiting-advanced
     consumer_group: Basic
     config:
       limit: 
       - 5
       window_size: 
       - 30
       window_type: sliding
       retry_after_jitter_max: 0
       namespace: basic
   - name: rate-limiting-advanced
     consumer_group: Premium
     config:
       limit: 
       - 500
       window_size: 
       - 30
       window_type: sliding
       retry_after_jitter_max: 0
       namespace: premium
append_to_existing_section: true
{% endentity_examples %}
   
This configures the different tiers like the following:
* **Free:** Allows six requests per second. This configuration sets the rate limit to three requests (`config.limit`) for every 30 seconds (`config.window_size`).
* **Basic:** Allows 10 requests per second. This configuration sets the rate limit to five requests (`config.limit`) for every 30 seconds (`config.window_size`).
* **Premium:** Allows 1,000 requests per second. This configuration sets the rate limit to 500 requests (`config.limit`) for every 30 seconds (`config.window_size`).

## 5. Apply configuration

{% include how-tos/steps/apply_config.md %}

## 6. Validate that rate limiting is working on each tier

Now we can test that each rate limiting tier is working as expected by sending a series of HTTP requests (for example, six for Free Tier and seven for Basic Tier) to the endpoint with the appropriate API key with the goal of exceeding the configured rate limit for that tier. The tests wait for one second between requests to avoid overwhelming the server and test rate limits more clearly.

Test the rate limiting of the Free tier:

```sh
echo "Testing Free Tier Rate Limit..."

for i in {1..6}; do
  curl -I http://localhost:8000/anything -H 'apikey:amal'
  echo
  sleep 1
done
```

For the first few requests (up to the configured limit, which is 3 requests in 30 seconds), you should receive a `200 OK` status code. Once the limit is exceeded, you should receive a `429 Too Many Requests` status code with a message indicating the rate limit has been exceeded.

Test the rate limiting of the Basic tier:
```sh
echo "Testing Basic Tier Rate Limit..."

for i in {1..7}; do
  curl -I http://localhost:8000/anything -H 'apikey:dana'
  echo
  sleep 1
done
```

For the first few requests (up to the configured limit, which is 5 requests in 30 seconds), you should receive a `200 OK` status code. After exceeding the limit, you should receive a `429 Too Many Requests` status code with a rate limit exceeded message.

Test the rate limiting of the Premium tier:
```sh
echo "Testing Premium Tier Rate Limit..."

for i in {1..11}; do
  curl -I http://localhost:8000/anything -H 'apikey:mahan'
  echo
  sleep 1
done
```

For the initial requests (up to the configured limit, which is 500 requests in 30 seconds), you should receive a `200 OK` status code. After exceeding the limit, you should receive a `429 Too Many Requests` status code.


