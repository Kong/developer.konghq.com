---
title: How to create rate limiting tiers with Kong Gateway
related_resources:
  - text: Consumer Group API documentation
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - ui

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

min_version:
  gateway: 3.4.x

plugins: 
  - rate-limiting-advanced
  - key-auth

entites:
  - consumer
  - consumer_group

tier: enterprise

tags:
  - rate-limiting

content_type: tutorial

tldr: 
  q: How do I rate limit different tiers of users, such as free vs. premium subscribers, in my API using Kong Gateway?
  a: To effectively manage API traffic for various user tiers (such as free, basic, and premium subscribers) you can create consumer groups for each tier and assign individual consumers to these groups. Then, configure the Rate Limiting Advanced plugin to apply specific rate limits based on these groups. This setup allows you to enforce customized request limits for each tier, ensuring fair usage and optimizing performance for high-value users.

faqs:
  - q: Why can't I use the regular Rate Limiting plugin to rate limit tiers of consumers?
    a: In this tutorial, we use the Rate Limiting Advanced plugin because it supports sliding windows, which we use to apply the rate limiting logic while taking into account previous hit rates (from the window that immediately precedes the current) using a dynamic weight.

tools:
    - deck

cleanup:
  inline:
    - title: Destroy the Kong Gateway container
      include_content: cleanup/products/gateway
---

## Steps

1. Add the following content to `kong.yaml` to enable the Key Authentication plugin. You need [authentication](/authentication/) to identify the consumer and apply rate limiting.

{% capture plugin %}
{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}
{% endcapture %}
{{ plugin | indent: 3 }}

1. Create the Free, Basic, and Premium tier consumer groups:

{% capture groups %}
{% entity_examples %}
entities:
  consumer_groups:
    - name: Free
    - name: Basic
    - name: Premium
{% endentity_examples %}
{% endcapture %}
{{ groups | indent: 3 }}

   Add this configuration to a `kong.yaml` file in a `deck_files` directory.

1. Synchronize your configuration

   Check the differences in your files:
   ```sh
   deck gateway diff deck_files
   ```

   If everything looks right, synchronize them to update your Kong Gateway configuration:
   ```sh
   deck gateway sync deck_files
   ```

1. Create three consumers, one for each tier:
  
{% capture consumers %}
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
{% endcapture %}
{{ consumers | indent: 3 }}

   Append this to your `kong.yaml` file. By adding key auth credentials here you can test later that rate limiting was correctly configured for the different tiers.

1. Synchronize your configuration

   Check the differences in your files:
   ```sh
   deck gateway diff deck_files
   ```

   If everything looks right, synchronize them to update your Kong Gateway configuration:
   ```sh
   deck gateway sync deck_files
   ```

1. Enable the Rate Limiting Advanced plugins for each tier:

{% capture groups %}
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
{% endcapture %}
{{ groups | indent: 3 }}
   
   This configures the different tiers like the following:
   * **Free:** Allows six requests per second. This configuration sets the rate limit to three requests (`config.limit`) for every 30 seconds (`config.window_size`).
   * **Basic:** Allows 10 requests per second. This configuration sets the rate limit to five requests (`config.limit`) for every 30 seconds (`config.window_size`).
   * **Premium:** Allows 1,000 requests per second. This configuration sets the rate limit to 500 requests (`config.limit`) for every 30 seconds (`config.window_size`).

1. Synchronize your configuration

   Check the differences in your files:
   ```sh
   deck gateway diff deck_files
   ```

   If everything looks right, synchronize them to update your Kong Gateway configuration:
   ```sh
   deck gateway sync deck_files
   ```

## Test

Each of these tests sends a series of HTTP requests (for example, six for Free Tier and seven for Basic Tier) to the endpoint with the appropriate API key with the goal of exceeding the configured rate limit for that tier. It waits for one second between requests to avoid overwhelming the server and test rate limits more clearly.

1. Test the rate limiting of the Free tier:

   ```sh
    echo "Testing Free Tier Rate Limit..."

    for i in {1..6}; do
      curl -I http://localhost:8000/anything -H 'apikey:amal'
      echo
      sleep 1
    done
   ```

   For the first few requests (up to the configured limit, which is 3 requests in 30 seconds), you should receive a `200 OK` status code. Once the limit is exceeded, you should receive a `429 Too Many Requests` status code with a message indicating the rate limit has been exceeded.

1. Test the rate limiting of the Basic tier:
   ```sh
    echo "Testing Basic Tier Rate Limit..."

    for i in {1..7}; do
      curl -I http://localhost:8000/anything -H 'apikey:dana'
      echo
      sleep 1
    done
   ```

   For the first few requests (up to the configured limit, which is 5 requests in 30 seconds), you should receive a `200 OK` status code. After exceeding the limit, you should receive a `429 Too Many Requests` status code with a rate limit exceeded message.

1. Test the rate limiting of the Premium tier:
   ```sh
    echo "Testing Premium Tier Rate Limit..."

    for i in {1..11}; do
      curl -I http://localhost:8000/anything -H 'apikey:mahan'
      echo
      sleep 1
    done
   ```

   For the initial requests (up to the configured limit, which is 500 requests in 30 seconds), you should receive a `200 OK` status code. After exceeding the limit, you should receive a `429 Too Many Requests` status code.


