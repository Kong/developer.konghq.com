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

Need a migration guide, manually done via specs tab, three dot menu, click migrate. Team will need this link to add to the UI. This migration creates an API entity that has the specs from the integration?

It's recommended because ......

steps here

## prereqs roles

for mapping APIs to services the user needs at the minimum the following combo roles on the service and API entities for actions:
Listing available APIs to link to a service: API viewer, Service viewer
Creating/deleting APi-service links: API viewer, Service admin
migration of legacy apis to new APIs: API creator, Service admin
listing linked services on the API overview page: API viewer, Service viewer
To perform all the above actions: API admin + creator and Service admin