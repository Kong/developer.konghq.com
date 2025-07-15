---
title: "Custom Dashboards reference"
content_type: reference
layout: reference
description: |
    Custom Dashboards allow you to create dashboards for your specific use cases.
breadcrumbs:
  - /advanced-analytics/
products:
    - advanced-analytics
tags:
  - custom-dashboards
works_on:
    - konnect
api_specs:
    - konnect/analytics-requests
schema:
    api: konnect/analytics-requests
related_resources:
  - text: Konnect Advanced Analytics
    url: /advanced-analytics/
  - text: Dev Portal analytics
    url: /dev-portal/analytics/
---

Custom Dashboards provide a flexible way to build, organize, and manage analytical views that are tailored to your organization’s needs. This functionality is available in [{{site.konnect_short_name}} Analytics](https://cloud.konghq.com/us/analytics/summary).

With [Dashboards](https://cloud.konghq.com/us/analytics/dashboards), you can create custom dashboards either from scratch or from a [template](#templates), and modify them from {{site.konnect_short_name}}.

## Templates

{% table %}
columns:
  - title: Template
    key: type
  - title: Description
    key: description
rows:
  - type: Quick summary dashboard
    description: High-level overview of your organization's API traffic and performance. This dashboard highlights top services, routes, and consumers across your Konnect organization with time-based trends for key performance metrics. It surfaces critical bottlenecks in the slowest services, routes, and consumers, helping you identify areas that may need optimization.
  - type: AI gateway dashboard
    description: AI-focused insight into your LLM traffic and operational costs. Track request volume by model and provider, understand token usage trends, and monitor latency across different models. This dashboard helps teams operating AI gateways to optimize performance and manage costs with visibility into traffic patterns and provider-specific behavior.
  - type: Shared services dashboard
    description: Health and performance of services managed inside your Konnect organization. This dashboard focuses on golden signals such as latency, error rates, and throughput, alongside detailed breakdowns of 4xx and 5xx responses, failed authentications, and rate limit hits. It provides a clear picture of how your services are behaving including which consumers and routes are most active or error-prone.
{% endtable %}

## Tiles

Tiles represent charts that you can add to your custom dashboard. You can create new chart tiles from scratch or add a tile from an existing report.

To add a new tile, select **New Tile** from the [Dashboards](https://cloud.konghq.com/us/analytics/dashboards/) view. After selecting from a series of charts, you'll be taken into a chart editor similar to the [Explorer](/advanced-analytics/explorer/) experience, where you can slice and dice the chart until it shows what you need.

In the **Edit tile** view, you can:

* Choose a chart type, such as time series line, bar, donut, or single value.
* Add filters to narrow down the data shown in the chart.
* Name the chart tile.
* Decide whether the chart should:
  * Use the global dashboard time range (automatically updates if a viewer changes the dashboard time), or
  * Use a fixed time range that always applies to this specific chart, regardless of dashboard-level settings.

If a [dashboard-level filter](#filters) is applied, it will also apply in the **Edit tile** view and is shown in the **Dashboard filters** section. However, be careful: these filters only affect the chart’s data as long as they remain applied to the dashboard. If someone removes the dashboard filter, the chart will no longer be filtered by it.

You can also add a tile by selecting an existing report, which lets you reuse previously created analytics configurations as dashboard tiles.

Each tile is customizable from the **Edit tile** view. You can select from a series of [filters](#filters), and modify the lines and time series. For more information on creating custom dashboards, review the [custom dashboard](/how-to/create-custom-dashboards/) documentation.


## Filters

Custom Dashboards support dashboard-level filters that apply across all tiles in a dashboard. Filters help users narrow down the data shown in charts without modifying individual tiles.

All users can add **temporary filters**, which apply only for the duration of the session. These filters allow users to explore data dynamically without changing the dashboard for others.

Admins can define **preset filters** when creating or editing a dashboard. Preset filters persist across sessions and are applied for all users viewing the dashboard. They are useful for:

* Ensuring viewers only see data they are authorized to access.
* Avoiding repetitive filter configuration across individual tiles.

Preset filters appear as badges at the top of the dashboard. Viewers with "Viewer" access can see these filters but cannot remove them. A lock icon indicates that the filter is preset and enforced. Hovering over the badge reveals the filter values for additional context.

![Example of a preset filter](/assets/images/analytics/admin.png)
>_**Figure 1:** An example of a preset filter_

## Role-based access

Organization Admins can control who is allowed to **view** a custom dashboard. This is currently the only available permission level—there are no editor or owner roles beyond the original dashboard creator.

To manage dashboard visibility, Organization Admins can assign roles to users through [**Organization**](https://cloud.konghq.com/organization/) > **Users** in {{site.konnect_short_name}}, using the **Role Assignments** tab. Only users with the appropriate roles will be able to access dashboards that are restricted to specific teams or audiences.

For more details, see the [teams and roles](/konnect/teams-and-roles/) documentation.


## Automation

Custom Dashboards can be managed programmatically to support automation and version control.

There are two primary ways to automate dashboard creation and updates:

* **API + JSON definition**: Use the [Konnect API](/api/konnect/analytics-requests/) along with the **Download definition as JSON** option available in the UI. This option provides the full dashboard definition in JSON format, which you can modify and use in API calls to create or update dashboards programmatically.

* **Terraform**: You can use [Terraform](/terraform/) to define and deploy dashboards as code, making it easier to integrate dashboard configuration into your infrastructure workflows.

These methods enable teams to standardize dashboard definitions, apply changes across environments, and maintain dashboards in version-controlled repositories.

