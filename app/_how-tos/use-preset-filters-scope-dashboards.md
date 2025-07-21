---
title: Use preset-filters to scope dashboards
description: Learn how to use preset-filters to scope {{site.konnect_short_name}} Analytics dashboards
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
    q: How do I use preset-filters to change the scope of a dashboard?
    a: Navigate to the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards), select an existing tile, use the **Add a filter** button to select from a list of filters and customization options.

prereqs:
  skip_product: true
  inline:
    - title: A {{site.konnect_short_name}} Analytics dashboard
      content: |
        This guide requires an existing {{site.konnect_short_name}} dashboard.  
        If you don’t have one, review the [Create a custom dashboard from a template](/how-to/create-custom-dashboard/) documentation.
related_resources:
  - text: Custom Dashboards
    url: /advanced-analytics/custom-dashboards/
next_steps:
  - text: Automate dashboard creation with Terraform
    url: /how-to/automate-dashboard-creation-terraform/
---

## Add filter

Custom Dashboards support dashboard-level filters that apply across all tiles in a dashboard. Filters help users narrow down the data shown in charts without modifying individual tiles.

1. To add a preset to an existing dashboard, select the [Dashboard](https://cloud.konghq.com/us/analytics/dashboards) section and navigate to an existing dashboard.

1. From the dashboard, select an existing tile and choose **edit**. 

1. From the **Edit tile** modal you can use the **Add filter** option to select from a list of filters. 


## Configure the filter

You can select from an existing filter and configure the options, in this case select the following: 

* Filter by: **Control plane**
* Operator: **In**
* Filter value: **default**

This will create a filter scoped to the default control plane. Click **Save** to save the configuration


## Validate

You can validate the filter is working succesfully by looking at the tile in your [Dashboard](https://cloud.konghq.com/us/analytics/dashboards).
The tile will now display information about your control plane. 