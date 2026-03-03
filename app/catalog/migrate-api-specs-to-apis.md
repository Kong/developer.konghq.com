---
title: "Migrate API specs in {{site.konnect_catalog}} to APIs"
content_type: reference
layout: reference
permalink: /catalog/migrate-api-specs-to-apis/
products:
    - catalog
works_on:
  - konnect

description: Learn how to migrate API specs in {{site.konnect_catalog}} to APIs.

breadcrumbs:
  - /catalog/
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Scorecards
    url: /catalog/scorecards/
  - text: "{{site.konnect_catalog}} integrations"
    url: /catalog/integrations/
---

APIs can be associated with {{site.konnect_catalog}} services, which replaces the legacy API spec linking. We recommend migrating API specs that are associated with a {{site.konnect_catalog}} service to APIs because this allows API consumers and service owners to see which APIs and services are associated with each other. 

{% include_cached /catalog/note-api-spec-snapshot.md %}

## Prerequisites

To migrate API specs to an API in {{site.konnect_catalog}}, you need the following [{{site.konnect_short_name}} roles](/konnect-platform/teams-and-roles/#catalog) at a minimum for the services and APIs:

<!--vale off-->
{% table %}
columns:
  - title: Action
    key: action
  - title: Required roles
    key: roles
rows:
  - action: List available APIs to link to a service
    roles: |
      * API viewer
      * Service viewer
  - action: Create or delete API and service links
    roles: |
      * API viewer
      * Service admin
  - action: Migrate legacy APIs to new APIs
    roles: |
      * API creator
      * Service admin
  - action: List linked services on the API overview page
    roles: |
      * API viewer
      * Service viewer
  - action: Perform all the above actions
    roles: |
      * API admin and creator
      * Service admin
{% endtable %}
<!--vale on-->

## Migrate API specs to APIs

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **Services**.
1. Click a Catalog service that has API specs associated with it.
1. Click the **API specs (legacy)** tab.
1. Click the action menu next to the API spec, and select "Migrate to API catalog". 
1. Click **Start migration**.

You will now see the API with your API spec linked to the {{site.konnect_catalog}} service. Users who view APIs will also be able to see any linked {{site.konnect_catalog}} services.