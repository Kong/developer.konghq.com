---
title: "{{site.konnect_short_name}} compatibility"
description: 'Details which browsers, software, and versions {{site.konnect_short_name}} is compatible with.'
content_type: policy
layout: reference
products:
    - gateway

tags:
  - compatibility

works_on:
  - konnect

  
related_resources:
  - text: "{{site.base_gateway}}"
    url: /gateway/
  - text: "Mesh Manager"
    url: /mesh-manager/
  - text: "decK"
    url: /deck/
  - text: "Plugins"
    url: /plugins/
---

This reference explains which browsers, software versions, tools, and applications {{site.konnect_short_name}} is compatible with.

## {{site.base_gateway}} version compatibility

{{site.konnect_short_name}} is compatible with the following versions of [{{site.base_gateway}}](/gateway/):

{% feature_table %}
item_title: "{{site.base_gateway}} version"
columns:
  - title: Supported?
    key: supported
  - title: Beginning with version
    key: beginning
  - title: End of support
    key: end

features:
  - title: 3.10.x
    supported: true
    beginning: 3.10.0.0
    end: April 2026
  - title: 3.9.x
    supported: true
    beginning: 3.9.0.0
    end: Dec 2025
  - title: 3.8.x
    supported: true
    beginning: 3.8.0.0
    end: Oct 2025
  - title: 3.7.x
    supported: true
    beginning: 3.7.0.0
    end: Jun 2025
  - title: 3.6.x
    supported: true
    beginning: 3.6.0.0
    end: Feb 2025
  - title: 3.5.x
    supported: true
    beginning: 3.5.0.0
    end: Nov 2024
  - title: 3.4.x (LTS)
    supported: true
    beginning: 3.4.0.0
    end: Aug 2026
  - title: 3.3.x
    supported: true
    beginning: 3.3.0.0
    end: May 2024
  - title: 3.2.x
    supported: true
    beginning: 3.2.1.0
    end: Feb 2024
  - title: 3.1.x
    supported: true
    beginning: 3.1.0.0
    end: Dec 2023
  - title: 3.0.x
    supported: true
    beginning: 3.0.0.0
    end: Sep 2023
  - title: 2.8.x (LTS)
    supported: true
    beginning: 2.8.0.0
    end: Mar 2025
  - title: 2.7.x
    supported: true
    beginning: 2.7.0.0
    end: Feb 2023
  - title: 2.6.x
    supported: true
    beginning: 2.6.0.0
    end: Feb 2023
  - title: 2.5.x
    supported: true
    beginning: 2.5.0.1
    end: Aug 2022
  - title: 2.4.x or earlier
    supported: false
    beginning: "-"
    end: "-"
  
{% endfeature_table %}


## {{site.mesh_product_name}} compatibility

To use [Mesh Manager](/mesh-manager/), you must also use a compatible version of {{site.mesh_product_name}}:

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