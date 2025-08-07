---
title: Create a custom dashboard
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
series:
  id: custom-dashboards
  position: 1
tldr:
    q: How do I create a Custom Dashboard in {{site.konnect_short_name}}
    a: Navigate to the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards), select **Create from Template** and apply filters.

prereqs:
  skip_product: true
  inline: 
    - title: Roles and permissions
      content: |
        This guide requires belonging to either the Organization admin or Analytics admin [teams](/konnect-platform/teams-and-roles/). 
related_resources:
  - text: Custom Dashboards
    url: /advanced-analytics/custom-dashboards/
  - text: Custom dashboards reference
    url: /advanced-analytics/custom-dashboards-reference/
  - text: Automate dashboards with Terraform
    url: /how-to/automate-dashboard-terraform/
---

## Create a dashboard

You can create custom dashboards either from scratch or from a [template](/advanced-analytics/custom-dashboards-reference/#templates). In this tutorial, we'll use a template.

To create a custom dashboard, follow these steps: 

1. Navigate to the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards) section.

1. Select **Create dashboard** > **Create from Template**.

1. Select **Quick summary dashboard**, then click **Use template**.


This creates a new template with pre-configured tiles.

## Add a filter

Filters help users narrow down the data shown in charts without modifying individual tiles. For this example, let's add a filter so that the data shown in the dashboard is scoped to only one control plane: 

1. From the dashboard, select **Add filter** to bring up the configuration options.

1. Configure a filter on the desired control plane:
  * Filter by: `Control Plane`
  * Operator: `In`
  * Value: `default` 
1. Select **Make this a preset for all viewers**, then click **Apply**. 

This applies the filter to the dashboard. Anyone that views this dashboard will be viewing it scoped to the filter you created.


## Validate

You can verify that the dashboard filter was applied correctly from the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards) section of {{site.konnect_short_name}}. Now the dashboard displays a **Preset filters** tag, with your **Control plane in (default)** filter.

