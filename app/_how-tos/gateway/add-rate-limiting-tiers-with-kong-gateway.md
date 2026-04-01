---
title: Create rate limiting tiers with {{site.base_gateway}}
permalink: /how-to/add-rate-limiting-tiers-with-kong-gateway/
content_type: how_to
related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/
  - text: Consumer Group API documentation
    url: /api/gateway/admin-ee/#/operations/get-consumer_groups

description: Enforce customized rate limiting tiers by setting individual rate limits for different groups of Consumers.
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
  - consumer-group

tags:
  - rate-limiting

tldr:
  q: How do I rate limit different tiers of users, such as free vs. premium subscribers, in my API using {{site.base_gateway}}?
  a: |
    To manage API traffic for various user tiers (such as free, basic, and premium subscribers), you can create [Consumer Groups](/gateway/entities/consumer-group/) for each tier and assign individual [Consumers](/gateway/entities/consumer/) to these groups. 
    Then, configure the [Rate Limiting Advanced plugin](/plugins/rate-limiting-advanced/) to apply specific rate limits based on these groups. 
    This setup allows you to enforce customized request limits for each tier, ensuring fair usage and optimizing performance for high-value users.

faqs:
  - q: Why can't I use the regular Rate Limiting plugin to rate limit tiers of Consumers?
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

## Set up Consumer authentication

We need to set up [authentication](/gateway/authentication/) to identify the Consumer and apply rate limiting. In this guide, we'll be using the [Key Auth plugin](/plugins/key-auth/), but you can use any [authentication plugin](/plugins/?category=authentication). 

Run the following command to configure the Key Auth plugin:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Create Consumer Groups for each tier

Before you can enable rate limiting for tiers of users, we first have to create Consumer Groups for each tier and then add Consumers to those groups. Consumer Groups are solely a way to organize Consumers of your APIs. In this guide, we'll create three tiers (Free, Basic, and Premium), so we need to create a unique Consumer Group for each tier:

{% entity_examples %}
entities:
  consumer_groups:
    - name: Free
    - name: Basic
    - name: Premium
{% endentity_examples %}

## Create Consumers

Now that you've added Consumer Groups for each tier, you can create three Consumers, one for each tier. Here, we're manually adding Consumers for the sake of ease, but in a production environment, you could use a script that would automatically add Consumers to the correct groups as they sign up for a tier of service.

We're also adding key auth credentials (`key`) to each Consumer so they can authenticate and we can test later that rate limiting was correctly configured for the different tiers:

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

## Enable rate limiting on each tier

Enable the Rate Limiting Advanced plugin for each tier:

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
       - 10
       window_size: 
       - 30
       window_type: sliding
       retry_after_jitter_max: 0
       namespace: premium
{% endentity_examples %}
   
This configures the different tiers like the following:
* **Free:** This configuration sets the rate limit to three requests for every 30 seconds.
* **Basic:** This configuration sets the rate limit to five requests for every 30 seconds.
* **Premium:** This configuration sets the rate limit to ten requests for every 30 seconds.

## Validate that rate limiting is working on each tier

Now we can test that each rate limiting tier is working as expected by sending a series of HTTP requests (for example, six for Free Tier and seven for Basic Tier) to the endpoint with the appropriate API key with the goal of exceeding the configured rate limit for that tier. The tests wait for one second between requests to avoid overwhelming the server and test rate limits more clearly.


Test the rate limiting of the Free tier:

{% validation rate-limit-check %}
iterations: 4
url: '/anything'
headers:
  - 'apikey:amal'
{% endvalidation %}

Test the rate limiting of the Basic tier:

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
headers:
  - 'apikey:dana'
{% endvalidation %}

Test the rate limiting of the Premium tier:

{% validation rate-limit-check %}
iterations: 11
url: '/anything'
headers:
  - 'apikey:mahan'
{% endvalidation %}
