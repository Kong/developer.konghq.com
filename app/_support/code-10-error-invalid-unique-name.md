---
title: "Code 10 \"invalid unique name\" error when an entity name matches a reserved Admin API endpoint"
content_type: support
description: "This error is returned because of a pre-existing Admin API endpoint named 'auth'."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why do I get a Code 10 \"invalid unique name\" error when creating an entity named auth?"
  a: |
    This error is returned because of a pre-existing Admin API endpoint named `auth`. Route
    matching prefers the existing Admin API endpoint over a newly created entity, so entity
    names that collide with reserved endpoints (such as `auth`, `services`, `routes`, `consumers`,
    and others listed in the error) must be avoided when creating new entities.
related_resources: []
---

## Problem

Using a fresh `kong` image in DB mode after running `kong migrations bootstrap`, you try to get an Upstream named `auth` by making the request:

```bash
curl http://localhost:8001/upstreams/auth
```

The following error is returned:

```json
{"code":10,"name":"invalid unique name","message":"must not be one of: workspaces, consumers, certificates, services, routes, snis, upstreams, targets, consumer_groups, plugins, tags, ca_certificates, clustering_data_planes, parameters, vaults, key_sets, keys, filter_chains, files, legacy_files, workspace_entity_counters, consumer_reset_secrets, credentials, audit_requests, audit_objects, rbac_users, rbac_roles, rbac_user_roles, rbac_role_entities, rbac_role_endpoints, admins, developers, document_objects, applications, application_instances, groups, group_rbac_roles, login_attempts, keyring_meta, keyring_keys, event_hooks, licenses, consumer_group_plugins, consumer_group_consumers, rbac_user_groups"}
```

## Cause

This error is returned because of a pre-existing Admin API endpoint named `auth`.

## Solution

Along with the referenced list in the error, avoid the following entity names when creating new entities, because Route matching prefers the existing Admin API endpoint over the newly created one:

```
/keyring,
/timers,
/userinfo,
/endpoints,
/auth,
/status,
/cache,
/config,
/metrics,
/acme,
/ca_certificates,
/tags,
/vaults,
/certificates,
/consumers,
/keys,
/services,
/routes,
/admins,
/groups,
/oauth2,
/jwts,
/graphql_ratelimiting_advanced_cost_decoration,
/sessions,
/acme_storage,
/oauth2_tokens,
/acls,
/degraphql_routes,
/plugins,
/workspaces,
/snis,
/upstreams,
/targets,
/files,
/licenses,
/consumer_groups,
/developers,
/document_objects,
/applications,
/login_attempts,
```
