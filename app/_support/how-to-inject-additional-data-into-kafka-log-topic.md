---
title: How to inject additional data into Kafka log topic
content_type: support
published: false
description: The Kafka log plugin can inject additional data into its Kafka topic using the same technique as Kong's other logging plugins.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I inject additional data into the Kafka log plugin's topic?
  a: |
    The Kafka log plugin works the same underlying way as Kong's other log plugins, so additional data can be added to the log topic using the same technique.
---

## Overview

When using the Kafka log plugin to send client request logs to a Kafka consumer, is it possible to inject additional values into the Kafka topic?

## Steps

The Kafka log plugin works in the same underlying fashion as the other log plugins and additional data can be added using the technique described in the linked knowledge base article.

https://support.konghq.com/support/s/article/How-can-the-log-content-be-configured-when-using-one-of-the-Kong-logging-plugins
