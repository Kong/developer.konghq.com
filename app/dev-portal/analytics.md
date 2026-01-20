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
    Learn how to view contextual developer and Dev Portal analytics.
related_resources:
  - text: "{{site.konnect_short_name}} Analytics"
    url: /observability/
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
---

## Contextual developer application analytics

Developers can view analytics for authenticated traffic from their registered applications within the {{site.konnect_short_name}} Dev Portal. These metrics help developers monitor usage patterns and understand how different APIs are being consumed.

Each application has its own dashboard, which provides a high-level summary of the **Number of Requests**, **Average Error Rate**, and **Latency**, and charts for the following data points:

* Requests by API
* Latency by API
* Error code distribution

{:.info}
> All of these metrics can be viewed within a selected time frame of up to 90 days and are available exclusively to customers with [{{site.konnect_short_name}} {{site.observability}}](/observability/).

![Dev Portal Analytics](/assets/images/dev-portal/dev-portal-analytics.png)
> _**Figure 1:** An example dashboard for an application_

## {{site.konnect_short_name}} contextual Dev Portal analytics

The {{site.konnect_short_name}} platform provides built-in contextual analytics across the Dev Portal section, offering insights into portals, APIs, and applications. These platform-wide metrics help administrators monitor overall usage, performance, and traffic trends.

![{{site.konnect_short_name}} Portal Analytics](/assets/images/dev-portal/konnect-portal-analytics.png)
> _**Figure 2:** An example of {{site.konnect_short_name}} contextual analytics for an API version_

{:.info}
> * In addition to these high-level insights, administrators can explore the [{{site.konnect_short_name}} Analytics](https://cloud.konghq.com/analytics/summary) section to create custom reports, build dashboards, and view detailed request data for a more comprehensive and flexible understanding of portal activity.
> * Portal and API contextual analytics are available to all customers. Access to {{site.konnect_short_name}} Analytics and application contextual analytics insights requires {{site.observability}}.