---
title: Slack
content_type: reference
layout: reference

products:
    - catalog
    - gateway

tags:
  - integrations
  - slack

breadcrumbs:
  - /catalog/
  - /catalog/integrations/
search_aliases:
  - service catalog
works_on:
    - konnect
description: The Slack integration allows you to see Slack communication channels that are relevant to a {{site.konnect_catalog}} service.

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Import and map Slack resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-slack-resources/
discovery_support: true
discovery_default: true
bindable_entities: "Slack Channel"
mechanism: "pull/ingestion model"
---


The Slack integration allows you to see communication channels (via [Slack channels](https://slack.com/help/articles/360017938993-What-is-a-channel)) that are relevant to a {{site.konnect_catalog}} service.
{% include /catalog/multi-resource.md %}

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map Slack resources in {{site.konnect_catalog}}](/how-to/install-and-map-slack-resources/).

## Prerequisites

* You need the Slack Admin privileges to authorize the integration.

## Authenticate the Slack integration

1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**.
2. Select **Add Slack Instance**.
3. Select **Authorize in Slack**, and name the instance.
   Only Slack admins can authorize the integration.

Slack will ask you to grant consent to {{site.konnect_product_name}}. Both read and write scopes are required.

## Resources

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: Slack Channel 
    description: 
       A Slack channel that indicates who owns the {{site.konnect_catalog}} service. Ideally, this helps users identify who they can contact if they have questions about a service.
{% endtable %}
<!--vale on-->

## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->
