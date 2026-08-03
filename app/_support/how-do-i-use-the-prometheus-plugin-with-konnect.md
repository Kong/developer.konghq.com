---
title: Using the Prometheus plugin with Konnect
content_type: support
published: false
description: "Enable the `status_listener` on the data plane so its metrics can be scraped by Prometheus or other analytics tools."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I use the Prometheus plugin with Konnect?
  a: |
    Enable the `status_listener` on the data plane. This exposes a metrics endpoint that Prometheus (or other analytics tools) can scrape.
related_resources:
  - text: Kong Gateway configuration reference (`status_listen`)
    url: /gateway/configuration/#status-listen
  - text: Updating `kong.conf` to turn on the status listener (video)
    url: https://youtu.be/6rU_uht_HLo?t=264
  - text: Setting up Prometheus to work with the new status listener (video)
    url: https://youtu.be/6rU_uht_HLo?t=467
---

## Overview

We want to be able to use the Prometheus plugin in our Konnect environment. How do we accomplish this?

## Steps

You need to enable the `status_listener` on the data plane. This will allow the metrics to be scraped by Prometheus or other analytics tools.
