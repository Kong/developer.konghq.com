---
title: Create an Analytics Custom Dashboard from a template
description: Learn how to create a custom dashboard in {{site.konnect_short_name}} Analytics
content_type: how_to
automated_tests: false
products:
    - konnect-platform
    - advanced-analytics
works_on:
    - konnect
tools:
    - konnect-api
tags:
    - custom-dashboards

tldr:
    q: How do I create a Custom Dashboard in {{site.konnect_short_name}}
    a: Navigate to the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards), select **Create from Template**. 

prereqs:
  skip_product: true
related_resources:
  - text: Custom Dashboards
    url: /advanced-analytics/custom-dashboards/
faqs:
  - q: I just edited or deleted my spec, document, page, or snippet. Why don't I immediately see these changes live in the Dev Portal?
    a: If you recently viewed the related content, your browser might be serving a cached version of the page. To fix this, you can clear your browser cache and refresh the page. 
---

## Create a Dashboard

From {{site.konnect_short_name}}, navigate to the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards) section.
From here you will be able to create a dashboard from either a template or from scratch. 


## Select a template

The three types of templates available are: 

* Quick summary dashboard: Provides a high-level overview of key metrics and performance insights. 
* AI Gateway dashboard: Monitors [AI Gateway](/ai-gateway/) performance, traffic, latency, and errors. 
* Shared services dashboard: Centralizes shared service monitoring. 

Select **Quick summary dashboard**. This will create a dashboard template.

## Customize 

The dashboards template comes with pre-configured tiles that are monitoring your services by default.
You can configure by adding a new [chart](/analytics/#charts) or an existing [report](/analytics/#reports).
To add a new time series line, select **New Tile** and enter the following information: 
* **Name**: A name for the chart
* **Time range**: Use Dashboard time

Then configure the tile with the following options: 

{% table %}
columns:
  - title: Option
    key: option
  - title: Value
    key: value
rows:
  - option: From
    value: API Usage
  - option: Show
    value: Time series line
  - option: With
    value: Request Count
  - option: Per
    value: 30 minutes
  - option: By
    value: API
{% endtable %}

Click **Save** to see your tile from the dashboard. 