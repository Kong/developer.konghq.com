---
title: "{{site.konnect_short_name}} compatibility and support policy"
description: 'Details which browsers, software, and versions {{site.konnect_short_name}} is compatible with.'
content_type: policy
layout: reference
products:
  - konnect

tags:
  - compatibility
  - support-policy

works_on:
  - konnect

search_aliases:
  - version support policy

breadcrumbs:
  - /konnect/
related_resources:
  - text: "{{site.base_gateway}}"
    url: /gateway/
  - text: "decK"
    url: /deck/
  - text: "Plugins"
    url: /plugins/

faqs:
  - q: Are the {{site.konnect_short_name}} Control Plane and associated database migrations or upgrades done by Kong Inc.?
    a: The {{site.base_gateway}} Control Plane and its dependencies are fully managed by {{site.konnect_short_name}}. As new versions of {{site.base_gateway}} are released, {{site.konnect_short_name}} supports them as long as they are under our [active support schedule](/gateway/version-support-policy/).
  - q: Will {{site.konnect_short_name}} Control Plane upgrades always show incompatible messages on the API Gateway page in {{site.konnect_short_name}} if the Data Plane nodes are not the same version as the {{site.konnect_short_name}} Control Plane?
    a: An old configuration may still be 100% compatible with older Data Plane nodes and therefore not show any error messages in the {{site.konnect_short_name}} UI. If there are compatibility issues detected when pushing the payload down to the Data Plane, then this will be reflected in the UI.
  - q: Will new features be available if the {{site.konnect_short_name}} Control Plane detects incompatible Data Plane nodes?
    a: |
      New features will not be available for use or consumption on incompatible Data Plane nodes. You will see new features available in the {{site.konnect_short_name}} UI regardless of the Data Plane that is connected to the Control Plane in {{site.konnect_short_name}}. However, when an update payload is pushed to an incompatible Data Plane, the update will be automatically rejected by the Data Plane. 

      This is managed by a version compatibility layer that checks the payload before the update gets sent to the Data Plane. If there are concerns with the payload, metadata is added to the node. That metadata is what will display incompatibility warnings or errors in the {{site.konnect_short_name}} UI. 

      For example, let's say a parameter is introduced with a new version of a plugin and is available in the {{site.konnect_short_name}} UI. The Data Plane, however, is running an older version of {{site.base_gateway}} and doesn't support the new parameter. If that parameter isn't configured, or is assigned the default value, then no warning or incompatibility metadata will be applied to the node in {{site.konnect_short_name}}, and no warnings or errors will appear.
  - q: Can I continue to use older versions of configurations as the {{site.konnect_short_name}} Control Plane auto-upgrades?
    a: Yes. All decK dumps, or YAML configurations, will continue to work in {{site.konnect_short_name}} after they are synced.
  - q: Are there any disruptions if I choose not to upgrade my Data Plane nodes?
    a: There is **no** disruption at all if you choose **not** to upgrade your Data Plane nodes as long as the version of the Data Plane is under our [{{site.base_gateway}} active support timeline](/konnect-platform/compatibility/#kong-gateway-version-compatibility). 
  - q: How can I create a support case in {{site.konnect_short_name}}?
    a: |
      If you're an org admin with an Enterprise account and a [Kong Support portal](https://support.konghq.com/support/s/) account, you can create a support case in {{site.konnect_short_name}} by navigating to the **?** icon on the top right menu and clicking **Create support case**. 

      This opens a pop-up dialog where you can enter your case type, description, and the related {{site.konnect_short_name}} entity.

      You can see your support cases in the [Kong Support portal](https://support.konghq.com). 
      
      If you don't have a Kong Support portal account, request access from your org admin or reach out to a Kong representative for an invite.
---

This reference explains which browsers, software versions, tools, and applications {{site.konnect_short_name}} is compatible with.

## {{site.base_gateway}} version compatibility

{{site.konnect_short_name}} is compatible with the following versions of [{{site.base_gateway}}](/gateway/):

{% include_cached support/konnect_gateway_support.html %}

## {{site.mesh_product_name}} compatibility

To use Mesh in {{site.konnect_short_name}}, you must use a compatible version of {{site.mesh_product_name}}:

{% feature_table %}
item_title: "{{site.mesh_product_name}} version"
columns:
  - title: Supported?
    key: supported
  - title: First supported patch
    key: beginning

features:
  - title: 2.4.x or later
    supported: true
    beginning: 2.4.1
  - title: 2.3.x or earlier
    supported: false
    beginning: "-"

{% endfeature_table %}

## decK version compatibility

{{site.konnect_short_name}} requires [decK](/deck/) v1.40.0 or above. 
Versions below this will see inconsistent `deck gateway diff` results and other potential issues.

## Supported browsers

{{site.konnect_short_name}} is compatible with the following browsers:

{% include_cached support/browsers.html %}

## Plugin compatibility

Most {{site.base_gateway}} plugins are compatible with {{site.konnect_short_name}}.
See the [Kong Plugin Hub](/plugins/?deployment-topology=konnect) for all compatible plugins.

### Considerations for Dedicated Cloud Gateways

There are some limitations for plugins with [Dedicated Cloud Gateways](/dedicated-cloud-gateways/):

* Any plugins that depend on a local agent will not work with Dedicated Cloud Gateways.
* Any plugins that depend on the Status API or on Admin API endpoints will not work.
* Any plugins or functionality that depend on the AWS IAM `AssumeRole` must be configured differently.
This includes [Data Plane Resilience](/gateway/cp-outage/).