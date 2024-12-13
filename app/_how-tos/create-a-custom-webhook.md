---
title: Create a custom webhook to push information to Slack
content_type: how_to

related_resources:
  - text: Event hooks
    url: /gateway/entities/event_hooks

works_on:
    - on-prem

tags:
  - eventhooks
  - webhook
  - notifications
tldr: 
  q: How do I create a custom webhook using eventhooks
  a: Send a `POST` request to the event_hooks endpoint containing the source, event, template and URL for your webhook. 

prereqs:
  entities:
    upstream:
        - example-upstream
    routes:
        - example-route
---



{:.warning}
> **Important**:  Before you can use event hooks for the first time, {{site.base_gateway}} needs to be reloaded.
