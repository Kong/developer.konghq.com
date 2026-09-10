---
title: Keeping Kong Functional During DB Down Times
content_type: support
description: Configure database cache TTLs, warmup entities, and memory settings so {{site.base_gateway}} keeps proxying during database maintenance or downtime.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the related pull request
    url: https://github.com/Kong/kong/pull/4565
tldr:
  q: How can {{site.base_gateway}} stay functional when the database is down?
  a: |
    Configure `db_cache_ttl`, `db_resurrect_ttl`, `db_update_frequency`, and `db_cache_warmup_entities` to keep the cache resilient and minimize database dependency during downtime. Increase `mem_cache_size` if warming additional entities triggers cache-size warnings in the logs.
---

## Problem

When the database is down—due to maintenance or other reasons—{{site.base_gateway}} needs additional configuration to keep functioning without interruption.

## Solution

During periods when the database is down—due to maintenance or other factors—you can configure several settings to minimize impact and keep the Gateway operational. Assuming you use the DB strategy, the only limitation is that vitals may not be written to the database during downtime.

Key configuration properties to manage cache behavior and provide resilience when the database is unavailable are:

- `db_cache_ttl`
- `db_resurrect_ttl`
- `db_update_frequency`

The `db_cache_warmup_entities` setting can be configured to prevent database access by warming up specific entities in the cache if they haven't been used recently. By default, only `services` are warmed up by this setting — `plugins` are pre-warmed separately and are explicitly ignored by `db_cache_warmup_entities`. You can include other entities, such as:

- `acls`
- `acme_storage`
- `basicauth_credentials`
- `ca_certificates`
- `certificates`
- `clustering_data_planes`
- `consumers`
- `hmacauth_credentials`
- `jwt_secrets`
- `keyauth_credentials`
- `oauth2_authorization_codes`
- `oauth2_credentials`
- `oauth2_tokens`
- `parameters`
- `ratelimiting_metrics`
- `rbac_roles`
- `rbac_users`
- `services`
- `sessions`
- `snis`
- `targets`
- `upstreams`
- `workspaces`

Adjust `mem_cache_size` if warnings about cache size appear in the logs due to warming multiple entities.

Note: The `routes` entity does not require warming since it is cached in the in-memory router object. See the related pull request for reference.
