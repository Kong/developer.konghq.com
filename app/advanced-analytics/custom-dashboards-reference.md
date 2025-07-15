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

## Tiles

You can add new tiles to any custom dashboard by selecting **New Tile** from the [dashboard](https://cloud.konghq.com/us/analytics/dashboards/).

The following types of tables are available: 

* Timeseries line
* Timeseries bar
* Horizontal bar
* Vertical bar
* Donut
* Single Value

Each tile type is customizable from the **Edit tile** view. You can select from a series of [filters](#filters), and modify the lines and time series. For more information on creating custom dashboards, review the [custom dashboard](/how-to/create-custom-dashboards/) documentation.

## Filters

Custom Dashboards includes a set of pre-set filters for dashboards:

* **API**
* **API Product**
* **API Product Version**
* **Application**
* **Consumer**
* **Control Plane**
* **Control Plane Group**
* **Data Plane Node**
* **Data Plane Node Version**
* **Gateway Services**
* **Response Source**
* **Portal**
* **Route**
* **Status Code**
* **Status Code Group**
* **Upstream Status Code**
* **Upstream Status Code Group**


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

## Role-based access

Administrators can limit visibility of dashboards using role-based access control (RBAC). This enables safe delegation of dashboard views to specific teams without exposing sensitive or unnecessary data. You can manage a user's roles by navigating to [**Organization**](https://cloud.konghq.com/organization/) > **Users** in {{site.konnect_short_name}} and clicking the **Role Assignments** tab for a user.

For more information review the [teams and roles](/konnect-platform/teams-and-roles/) documentation.