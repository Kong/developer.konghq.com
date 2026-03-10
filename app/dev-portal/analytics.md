---
title: Dev Portal analytics
content_type: reference
layout: reference

products:
    - dev-portal

breadcrumbs: 
  - /dev-portal/
tags:
  - analytics

works_on:
    - konnect
description: | 
    Learn how to view contextual developer, client app, and Dev Portal analytics.
related_resources:
  - text: "{{site.konnect_short_name}} Analytics"
    url: /observability/
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: Add the Google Tag Manager script to Dev Portal
    url: /dev-portal/google-tag-manager/
  - text: Send Dev Portal events data to Google Analytics
    url: /dev-portal/google-analytics/
---

## Contextual analytics

Contextual analytics help you analyze the usage, performance, and traffic of your Dev Portal.

### Contextual developer application analytics

Developers can view analytics for authenticated traffic from their registered applications within the {{site.konnect_short_name}} Dev Portal. These metrics help developers monitor usage patterns and understand how different APIs are being consumed.

Each application has its own dashboard, which provides a high-level summary of the **Number of Requests**, **Average Error Rate**, and **Latency**, and charts for the following data points:

* Requests by API
* Latency by API
* Error code distribution

{:.info}
> All of these metrics can be viewed within a selected time frame of up to 90 days and are available exclusively to customers with [{{site.konnect_short_name}} {{site.observability}}](/observability/).

![Dev Portal Analytics](/assets/images/dev-portal/dev-portal-analytics.png)
> _**Figure 1:** An example dashboard for an application_

### {{site.konnect_short_name}} contextual Dev Portal analytics

The {{site.konnect_short_name}} platform provides built-in contextual analytics across the Dev Portal section, offering insights into Dev Portals, APIs, and applications. These platform-wide metrics help administrators monitor overall usage, performance, and traffic trends.

![{{site.konnect_short_name}} Portal Analytics](/assets/images/dev-portal/konnect-portal-analytics.png)
> _**Figure 2:** An example of {{site.konnect_short_name}} contextual analytics for an API version_

{:.info}
> * In addition to these high-level insights, administrators can explore the [{{site.konnect_short_name}} Analytics](https://cloud.konghq.com/analytics/summary) section to create custom reports, build dashboards, and view detailed request data for a more comprehensive and flexible understanding of portal activity.
> * Portal and API contextual analytics are available to all customers. Access to {{site.konnect_short_name}} Analytics and application contextual analytics insights requires {{site.observability}}.

## Client app analytics

Analyze web traffic, user behavior, and engagement for your Dev Portal with [Google Analytics](https://developers.google.com/analytics) and [Google Tag Manager](https://marketingplatform.google.com/about/tag-manager/). By integrating these with Dev Portal, you can analyze the following:
* Which API docs get the most traffic?
* Where do developers drop off and bounce on a page?
* Are developers finding the search useful? Are they searching for something that isn't in the Dev Portal?
* If Google Tag Manager is set up to track tab clicks, which SDK or language tab do developers prefer?
* What does the Dev Portal conversion funnel look like?

### Integrate Google Analytics with Dev Portal

To configure the Google Analytics integration, do the following:

{% navtabs "analytics-integrations" %}
{% navtab "UI" %}

{% include /dev-portal/google-analytics-integration.md %}

You can verify that the integrations are working as expected by navigating to your Dev Portal URL and inspecting the Network information on the page. You should see your Google Analytics information there.
{% endnavtab %}
{% navtab "API" %}

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/integrations
status_code: 200
method: PATCH
body:
  google_analytics_4:
    enabled: true
    type: analytics
    consent_required: false
    config_data:
      id: $GOOGLE_ANALYTICS_TRACKING_ID
{% endkonnect_api_request %}
<!--vale on-->

You can verify that the integrations are working as expected by navigating to your Dev Portal URL and inspecting the Network information on the page. You should see your Google Analytics information there.
{% endnavtab %}
{% endnavtabs %}

### Integrate Google Tag Manager with Dev Portal

To configure the Google Tag Manager integration, do the following:

{% navtabs "analytics-integrations" %}
{% navtab "UI" %}

{% include /dev-portal/google-tag-manager-integration.md %}

You can verify that the integrations are working as expected by navigating to your Dev Portal URL and inspecting the Network information on the page. You should see your Google Tag Manager information there.
{% endnavtab %}
{% navtab "API" %}

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/integrations
status_code: 200
method: PATCH
body:
  google_tag_manager:
    enabled: true
    type: tracking
    consent_required: false
    config_data:
      id: $GOOGLE_TAG_MANAGER_CONTAINER_ID
{% endkonnect_api_request %}
<!--vale on-->

You can verify that the integrations are working as expected by navigating to your Dev Portal URL and inspecting the Network information on the page. You should see your Google Tag Manager information there.
{% endnavtab %}
{% endnavtabs %}