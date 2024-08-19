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

min_version:
  gateway: 3.4.x

plugins: 
  - rate-limiting-advanced

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
---

## Steps

1. Create the Free, Basic, and Premium tier consumer groups:
  ```yaml
  _format_version: '3.0'
  consumer_groups:
  - name: Free
  - name: Basic
  - name: Premium
  ```
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

1. Create four consumers, one for each tier and one that won't be assigned to a consumer group tier:
  
  ```yaml
  consumers:
  - username: Amal
    groups:
    - name: Free
  - username: Dana
    groups:
    - name: Basic
  - username: Mahan
    groups:
    - name: Premium
  - username: Rosario
  ```

  Apphend this to your `kong.yaml` file. 

  In this tutorial, one consumer won't be assigned to a tier, which is a consumer group. Consumers that are not in a consumer group default to the Rate Limiting advanced plugin’s configuration, so you can define tier groups for some users and have a default behavior for consumers without groups.

1. Synchronize your configuration

   Check the differences in your files:
   ```sh
   deck gateway diff deck_files
   ```

   If everything looks right, synchronize them to update your Kong Gateway configuration:
   ```sh
   deck gateway sync deck_files
   ```

1. Enable the Rate Limiting and Rate Limiting Advanced plugins for each tier:
  ```yaml
  plugins:
  - consumer_group: Free
    config:
      limit: 3
      window_size: 30
      window_type: sliding
      retry_after_jitter_max: 0
    name: rate-limiting-advanced
  - consumer_group: Basic
    config:
      limit: 5
      window_size: 30
      window_type: sliding
      retry_after_jitter_max: 0
    name: rate-limiting-advanced
  - consumer_group: Premium
    config:
      limit: 500
      window_size: 30
      window_type: sliding
      retry_after_jitter_max: 0
    name: rate-limiting-advanced
  - name: rate-limiting
    config:
      second: 5
      hour: 10000
      policy: local
  ```
  Apphend this to your `kong.yaml` file.
  
  This configures the different tiers like the following:
  * **Free:** Allows six requests per second. This configuration sets the rate limit to three requests (`config.limit`) for every 30 seconds (`config.window_size`).
  * **Basic:** Allows 10 requests per second. This configuration sets the rate limit to five requests (`config.limit`) for every 30 seconds (`config.window_size`).
  * **Premium:** Allows 1,000 requests per second. This configuration sets the rate limit to 500 requests (`config.limit`) for every 30 seconds (`config.window_size`).
  * **Global:** Allows five HTTP requests per second (`config.second`), 10,000 HTTP requests per hour (`config.hour`), and uses a local policy (`config.local`).

1. Synchronize your configuration

   Check the differences in your files:
   ```sh
   deck gateway diff deck_files
   ```

   If everything looks right, synchronize them to update your Kong Gateway configuration:
   ```sh
   deck gateway sync deck_files
   ```

1. Run the following command to test the rate limiting as the consumer:

  ```sh
  for _ in {1..6}; do curl -i http://localhost:8000/example_route -H 'apikey:example_key'; echo; done
  ```

  You should get a 429 error with the message API rate limit exceeded.

## Cleanup

If you used the Kong Gateway quickstart from the prerequistes, destroy the Kong Gateway container:

```sh
curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
```


