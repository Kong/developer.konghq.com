---
title: Create a dashboard from a template
permalink: /how-to/create-custom-dashboards/
description: Learn how to create a dashboard from a template in {{site.konnect_short_name}} Analytics.
content_type: how_to
automated_tests: false
products:
    - observability
    - konnect
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
    q: How do I create a dashboard from a template in {{site.konnect_short_name}}?
    a: Navigate to the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards), select "Create from Template" from the **Create dashboard** dropdown menu, and apply filters.

prereqs:
  show_works_on: false
  inline: 
    - title: Roles and permissions
      content: |
        You must be either an [Organization admin or Analytics admin](/konnect-platform/teams-and-roles/). 
related_resources:
  - text: Custom Dashboards
    url: /custom-dashboards/
  - text: Custom dashboards reference
    url: /observability/custom-dashboards-reference/
  - text: Automate dashboards with Terraform
    url: /how-to/automate-dashboard-terraform/
---

## Create a dashboard

You can create custom dashboards either from scratch or from a [template](/observability/custom-dashboards-reference/#templates). In this tutorial, we'll use a template.

To create a custom dashboard, do the following: 

1. In the {{site.konnect_short_name}} sidebar, click **{{site.observability}}**.
1. In the {{site.observability}} sidebar, click [**Dashboards**](https://cloud.konghq.com/us/analytics/dashboards).
1. From the **Create dashboard** dropdown menu, select "Create from template".
1. Click **Quick summary dashboard**.
1. Click **Use template**.


This creates a new template with pre-configured tiles.

## Add a filter

Filters help you narrow down the data shown in charts without modifying individual tiles. 

For this example, let's add a filter so that the data shown in the dashboard is scoped to only one control plane: 

1. From the dashboard, click **Add filter**. This brings up the configuration options.
1. Select "Control plane" from the **Filter by** dropdown menu.
1. Select "In" from the **Operator** dropdown menu.
1. Select "default" from the **Filter value** dropdown menu.
1. Select the **Make this a preset for all viewers** checkbox.
1. Click **Apply**. 

This applies the filter to the dashboard. Anyone that views this dashboard will be viewing it scoped to the filter you created.


## Validate

You can verify that the dashboard filter was applied correctly by navigating to the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards) section of {{site.konnect_short_name}}. Now the dashboard displays a **Preset filters** tag, with your **Control plane in (default)** filter.

