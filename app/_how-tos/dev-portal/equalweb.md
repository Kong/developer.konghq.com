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
        Configure the EqualWeb widget with your {{site.dev_portal}} domain. 
        In your {{site.dev_portal}} settings, click the **Integrations** tab and enable the EqualWeb integration. 
        Add your EqualWeb site key and widget configuration.
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
        You need an [EqualWeb](https://www.equalweb.com/) account.
      icon_url: /assets/icons/third-party/equalwebicon.png
---

You can add the [EqualWeb](https://www.equalweb.com/) accessibility widget to your {{site.dev_portal}} to help meet your organization's accessibility requirements. 
After it's configured, the EqualWeb widget script will be injected into every page of your {{site.dev_portal}}.

## Get your EqualWeb site key

Before you configure the integration in {{site.konnect_short_name}}, you need your {{site.dev_portal}} domain and your EqualWeb site key.

1. In the {{site.konnect_short_name}} sidebar, expand **{{site.dev_portal}}**.
1. Click **Portals**.
1. Click your {{site.dev_portal}}.
1. Copy your {{site.dev_portal}} domain. This is the URL you'll register in EqualWeb. You can use either the default {{site.konnect_short_name}}-generated domain or your custom domain if you've configured one.
1. In your EqualWeb account, click **Add new site**.
1. In the **Insert your domain** field, enter your {{site.dev_portal}} domain.
1. Click **Continue to customize design**.
1. Configure the widget design settings as needed.
1. Click **Continue to install widget**.
1. Click **Collapse** for your widget code.
1. Copy your site key from the `get sitekey (){ return "1234..."}` field. For example: `79ad2e1ec52e63565e254555077aaaec`.
1. (Optional) If you configured the widget design, copy the configuration. For example:
   ```json
   "Position": "left",
    "Menulang": "EN",
    "draggable": true,
    "btnStyle": {
        "vPosition": [
            "80%",
            "80%"
        ],
        "margin": [
            "0",
            "0"
        ],
        "scale": [
            "0.5",
            "0.5"
        ],
        "color": {
            "main": "#1c4bb6",
            "second": "#ffffff"
        },
        "icon": {
            "outline": false,
            "outlineColor": "#ffffff",
            "type":  1 ,
            "shape": "circle"
        }
    }
   ```
   {:.collapsible}

## Configure the EqualWeb integration

Configure the EqualWeb integration in your {{site.dev_portal}} settings.

1. In the {{site.konnect_short_name}} sidebar, expand **Dev Portal**.
1. Click **Portals**.
1. Click your Dev Portal.
1. Click the **Settings** tab.
1. Click the **Integrations** tab.
1. Click **EqualWeb**.
1. Click the **Enabled** toggle.
1. In the **Site key**, enter the site key from the EqualWeb widget you configured in the previously. For example: `79ad2e1ec52e63565e254555077aaaec`.
1. (Optional) If you configured the widget design in EqualWeb, click **Advanced configurations** and enter the JSON configuration in the **** field with opening and closing brackets. For example:
   ```json
   {
    "Position": "left",
    "Menulang": "EN",
    "draggable": true,
    "btnStyle": {
        "vPosition": [
            "80%",
            "80%"
        ],
        "margin": [
            "0",
            "0"
        ],
        "scale": [
            "0.5",
            "0.5"
        ],
        "color": {
            "main": "#1c4bb6",
            "second": "#ffffff"
        },
        "icon": {
            "outline": false,
            "outlineColor": "#ffffff",
            "type":  1 ,
            "shape": "circle"
        }
    }
   }
   ```
   {:.collapsible}
1. Click **Save**.


You can also configure the EqualWeb integration using the {{site.konnect_short_name}} API by sending a `PUT` request to the `/portals/{portalId}/integrations` endpoint.

## Validate

You can verify that the integration is working as expected by navigating to your {{site.dev_portal}} URL. 
The EqualWeb accessibility widget should display on the page.
It can take several minutes to display the widget after you've enabled the integration.
