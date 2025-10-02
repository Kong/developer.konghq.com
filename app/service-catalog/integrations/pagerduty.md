---
title: "PagerDuty"
content_type: reference
layout: reference

products:
    - service-catalog
    - gateway

tags:
  - integrations
  - pagerduty

breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The PagerDuty integration allows you to provide a way to alert on information about current open incidents to consumers of the service directory.
related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
  - text: Import and map PagerDuty resources in Service Catalog
    url: /how-to/install-and-map-pagerduty-resources/
discovery_support: true
bindable_entities: "PagerDuty Service"
---

The PagerDuty integration allows you to provide a way to alert the service team (via PagerDuty services), as well as provide information on current open incidents to consumers of the service directory.
{% include /service-catalog/multi-resource.md %}

For each linked PagerDuty service, a summary will be provided on the Service Catalog service's details page, showing current unresolved incidents and the current on-call user.

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map PagerDuty resources in Service Catalog](/how-to/install-and-map-pagerduty-resources/).

## Authenticate the PagerDuty integration

1. From the **Catalog** in {{site.konnect_short_name}}, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **Add PagerDuty Instance**
3. Configure the **Region**, add **authorization**, and name the instance `pagerduty`. PagerDuty will ask you to grant consent to {{site.konnect_short_name}}. Both Read and Write scopes are required.

## Resources

Available PagerDuty resources:

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: PagerDuty Service
    description: 
      A PagerDuty service is any entity that can have incidents opened on it. In practice it could be a service, but could also be a group of services or an organization/team.
{% endtable %}
<!--vale on-->

## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->