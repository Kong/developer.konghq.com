---
title: "PagerDuty"
content_type: reference
layout: reference
beta: true

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
  - text: "{{site.konnect_catalog}}"
    url: /service-catalog/
discovery_support: true
bindable_entities: "PagerDuty Service"
---

The PagerDuty integration allows you to provide a way to alert the service team (via PagerDuty services), as well as provide information on current open incidents to consumers of the service directory. 

For each linked PagerDuty service, a summary will be provided on the {{site.konnect_catalog}} service's details page, showing current unresolved incidents and the current on-call user.

## Authenticate the PagerDuty integration

1. From the **{{site.konnect_catalog}}** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **PagerDuty**, then **Install PagerDuty**.
3. Select **Authorize**. 

PagerDuty will ask you to grant consent to {{site.konnect_short_name}}. **Both Read and Write scopes are required.**

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