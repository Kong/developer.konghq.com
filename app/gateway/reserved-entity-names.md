---
title: "Reserved entity names"
content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

description: See which {{site.base_gateway}} entity names are reserved.

related_resources:
  - text: Gateway entities
    url: /gateway/entities/
---

The {{site.base_gateway}} maintains a list of reserved entity names which can't be used when naming [Workspaces](/gateway/entities/workspace/) or [other entities](/gateway/entities/).

For example, a Workspace can't be named `consumers` or `vaults`. Doing so will yield a `schema violation` error response.

The reserved entity names are the following:

* `admins`
* `applications`
* `application_instances`
* `audit_objects`
* `audit_requests`
* `ca_certificates`
* `certificates`
* `clustering_data_planes`
* `consumer_group_consumers`
* `consumer_group_plugins`
* `consumer_groups`
* `consumer_reset_secrets`
* `consumers`
* `credentials`
* `developers`
* `document_objects`
* `event_hooks`
* `filter_chains`
* `files`
* `group_rbac_roles`
* `groups`
* `key_sets`
* `keyring_keys`
* `keyring_meta`
* `keys`
* `licenses`
* `legacy_files`
* `login_attempts`
* `parameters`
* `plugins`
* `rbac_role_endpoints`
* `rbac_role_entities`
* `rbac_roles`
* `rbac_user_groups`
* `rbac_user_roles`
* `rbac_users`
* `routes`
* `services`
* `snis`
* `tags`
* `targets`
* `upstreams`
* `vaults`
* `workspaces`
* `workspace_entity_counters`