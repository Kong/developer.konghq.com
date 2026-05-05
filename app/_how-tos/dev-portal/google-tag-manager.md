---
title: "Add the Google Tag Manager script to Dev Portal"
permalink: /dev-portal/google-tag-manager/
description: "Learn how to add the Google Tag Manager script to all pages of your {{site.konnect_short_name}} Dev Portal."
content_type: how_to
related_resources:
  - text: About Dev Portal
    url: /dev-portal/
  - text: Dev Portal analytics
    url: /dev-portal/analytics/
  - text: Send Dev Portal events data to Google Analytics
    url: /dev-portal/google-analytics/
automated_tests: false
products:
    - dev-portal
    - gateway
works_on:
    - konnect

tldr:
    q: How do I add Google Tag Manager to my Dev Portal?
    a: |
        In the settings for your Dev Portal, click the **Integrations** tab, configure Google Tag Manager with your GTM container ID, and enable the integration.
tags:
    - analytics
prereqs:
  skip_product: true
  inline:
    - title: Dev Portal
      include_content: prereqs/dev-portal-create-ui
      icon_url: /assets/icons/dev-portal.svg
    - title: Google Tag Manager
      content: |
        You need an active Google Tag Manager account with a container configured. Copy and save your [container ID](https://support.google.com/tagmanager/answer/6103696).
      icon_url: /assets/icons/analytics.svg
---

You can add {{ site.google}} Tag Manager to your Dev Portal to manage tracking and analytics tags across all Dev Portal pages without modifying Dev Portal code. After it's configured, your {{ site.google}} Tag Manager container script will be injected into every page of your Dev Portal, allowing you to manage tags like {{ site.google}} Analytics and more from {{ site.google}} Tag Manager.

## Configure the {{ site.google}} Tag Manager integration

Configure the {{ site.google}} Tag Manager integration in your Dev Portal settings.

{% include /dev-portal/google-tag-manager-integration.md %}

## Validate

You can verify that the integration is working as expected by navigating to your Dev Portal URL and inspecting the Network information on the page. You should see your {{ site.google}} Tag Manager information there.