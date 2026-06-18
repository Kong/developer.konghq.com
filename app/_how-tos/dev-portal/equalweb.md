---
title: "Add the EqualWeb accessibility widget to {{site.dev_portal}}"
permalink: /dev-portal/equalweb/
description: "Learn how to add the EqualWeb accessibility widget to all pages of your {{site.konnect_short_name}} Dev Portal."
content_type: how_to
related_resources:
  - text: About {{site.dev_portal}}
    url: /dev-portal/
  - text: Add the Google Tag Manager script to {{site.dev_portal}}
    url: /dev-portal/google-tag-manager/
  - text: Send {{site.dev_portal}} events data to Google Analytics
    url: /dev-portal/google-analytics/
automated_tests: false
products:
    - dev-portal
    - gateway
works_on:
    - konnect

tldr:
    q: How do I add EqualWeb to my {{site.dev_portal}}?
    a: |
        In your {{site.dev_portal}} settings, click the **Integrations** tab and enable the EqualWeb integration. Add your EqualWeb site key and widget configuration.
tags:
    - accessibility
prereqs:
  skip_product: true
  inline:
    - title: "{{site.dev_portal}}"
      include_content: prereqs/dev-portal-create-ui
      icon_url: /assets/icons/dev-portal.svg
    - title: EqualWeb
      content: |
        You need an active EqualWeb account.
      icon_url: /assets/icons/third-party/equalwebicon.png
---

You can add the EqualWeb accessibility widget to your {{site.dev_portal}} to help meet your organization's accessibility requirements. 
After it's configured, the EqualWeb widget script will be injected into every page of your {{site.dev_portal}}.

## Get your EqualWeb site key

Before you configure the integration in {{site.konnect_short_name}}, you need your {{site.dev_portal}} domain and your EqualWeb site key.

1. In the {{site.konnect_short_name}} sidebar, expand **{{site.dev_portal}}**.
1. Click **Portals**.
1. Click your {{site.dev_portal}}.
1. Copy your {{site.dev_portal}} domain. This is the URL you'll register in EqualWeb. You can use either the default {{site.konnect_short_name}}-generated domain or your custom domain if you've configured one.
1. In your EqualWeb account, register your {{site.dev_portal}} domain and copy the site key from the widget installation code.

## Configure the EqualWeb integration

Configure the EqualWeb integration in your {{site.dev_portal}} settings.

1. In the {{site.konnect_short_name}} sidebar, expand **Dev Portal**.
1. Click **Portals**.
1. Click your Dev Portal.
1. Click the **Settings** tab.
1. Click the **Integrations** tab.
1. Click **EqualWeb**.
1. Click the **Enabled** toggle.
?
1. Click **Save**.

You can also do this in the {{site.konnect_short_name}} UI by navigating to your {{site.dev_portal}} and clicking the **Integrations** tab.

## Validate

You can verify that the integration is working as expected by navigating to your {{site.dev_portal}} URL. 
The EqualWeb accessibility widget should display on the page.
