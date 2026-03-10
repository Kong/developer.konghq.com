---
title: "Send Dev Portal events data to Google Analytics"
permalink: /dev-portal/google-analytics/
description: "Learn how to configure Google Analytics 4 to track events on your {{site.konnect_short_name}} Dev Portal."
content_type: how_to
related_resources:
  - text: About Dev Portal
    url: /dev-portal/
  - text: Dev Portal analytics
    url: /dev-portal/analytics/
  - text: Add the Google Tag Manager script to Dev Portal
    url: /dev-portal/google-tag-manager/
automated_tests: false
products:
    - dev-portal
    - gateway
works_on:
    - konnect

tldr:
    q: How do I send Dev Portal event data to Google Analytics?
    a: |
        In the settings for your Dev Portal, click the **Integrations** tab, configure Google Analytics 4 with your Google Analytics 4 measurement ID, and enable the integration.
tags:
    - analytics
prereqs:
  skip_product: true
  inline:
    - title: Dev Portal
      include_content: prereqs/dev-portal-create-ui
      icon_url: /assets/icons/dev-portal.svg
    - title: Google Analytics 4
      content: |
        You need an active Google Analytics 4 account with a data stream configured. Copy and save your [measurement ID](https://support.google.com/analytics/answer/9539598?hl=en).
      icon_url: /assets/icons/analytics.svg
---

You can integrate Google Analytics 4 with your Dev Portal to track developer activity and Dev Portal usage. Once configured, Google Analytics 4 will receive event data from your Dev Portal, allowing you to monitor page views, developer journeys, and API documentation engagement.

## Configure the Google Analytics 4 integration

Configure the Google Analytics integration in your Dev Portal settings.

{% include /dev-portal/google-analytics-integration.md %}

## Validate

You can verify that the integrations are working as expected by navigating to your Dev Portal URL and inspecting the Network information on the page. You should see your Google Analytics information there.