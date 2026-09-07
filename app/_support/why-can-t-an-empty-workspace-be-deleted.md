---
title: Cannot delete an empty workspace when `workspace_entity_counters` is out of sync
content_type: support
description: In some circumstances, the workspace metadata that stores the entity count can become unsynchronized.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why can't an empty workspace be deleted?"
  a: |
    Workspace deletion can fail with a `"Workspace is not empty"` error even when the Admin API shows no entities, because the `workspace_entity_counters` table can become out of sync with the actual entity counts. Fix it by running `kong migrations reinitialize-workspace-entity-counters`, or by manually resetting the counters for that workspace in the database. On Kong Gateway 3.14.0.0, workspace deletion checks live entity counts directly instead of these counters, so this specific issue no longer occurs.
related_resources:
  - text: the documentation for details of this command
    url: /gateway/reference/cli/#kong-migrations
---

## Problem

When deleting an empty workspace, an error is returned and the workspace is not deleted. The error message is as below;

```json
{
	"message": {
		"entities": {
			"mtls_auth_credentials": 1,
			"plugins": 1
		},
		"message": "Workspace is not empty"
	}
}
```

But when checking directly via the Admin API, there are no entities. For example, checking the plugins for the workspace;

```bash
curl http://api.kong.lan:8001/default/plugins
{"data":[],"next":null}
```

## Cause

In some circumstances, the workspace metadata that stores the entity count can become unsynchronized. This means that when an attempt is made to delete a workspace, the metadata count is not zero and so the deletion is prevented.

## Solution

There are two methods to fix this error. The first and most straightforward is to run the below `kong migrations` command;

```bash
kong migrations reinitialize-workspace-entity-counters
```

See the documentation for details of this command.

The second method is to manually update the workspace entity counters directly in the database. It is strongly recommended that you take a database backup before making any direct database changes.

To update the counters, follow the steps below (the example is for Postgres, similar updates can be run in Cassandra too but the queries will be slightly different due to limitations with Cassandra CQL queries).

1) Get the counters for the workspace. In our example, we will be using a workspace with a name of `delete-me`

```sql
kong=# select w.name, wec.* from workspaces w, workspace_entity_counters wec where w.id = wec.workspace_id and w.name = 'delete-me';
name      | workspace_id                         | entity_type           | count
----------+--------------------------------------+-----------------------+-------
delete-me | 20ac8a3c-ff1b-4d22-b2a0-3741737286b3 | plugins               | 1
delete-me | 20ac8a3c-ff1b-4d22-b2a0-3741737286b3 | mtls-auth-credentials | 1
(2 rows)
```

2) Ensure that the returned counters match the values in the error message when deleting the workspace. If these match, take note of the `workspace_id` value. If the counters do not match, check you have the correct workspace name in the query.

3) Update the `count` column to be 0 for the workspace;

```sql
kong=# update workspace_entity_counters set count = 0 where workspace_id = '20ac8a3c-ff1b-4d22-b2a0-3741737286b3';
UPDATE 2
```

After this, you should be able to delete the workspace via Kong Manager or the Admin API.

Note: on current Kong Gateway (Enterprise) 3.14.0.0, `DELETE /workspaces/{name}` no longer consults the `workspace_entity_counters` table at all when deciding whether a workspace is empty — it now runs a live `COUNT(*)` against each workspaceable entity table instead. This was confirmed by live-reproducing the exact scenario described above (deleting a plugin's and a service's underlying database rows directly, bypassing the Admin API's counter maintenance, so `workspace_entity_counters` was left showing stale non-zero counts while the Admin API itself reported zero entities): `DELETE /workspaces/{name}` still succeeded cleanly with `204`. This means the specific "Workspace is not empty" false-positive described in this article, and the `kong migrations reinitialize-workspace-entity-counters` / manual `UPDATE workspace_entity_counters` remediation, should no longer be necessary on 3.14.0.0 — a workspace-deletion failure with this exact message on a genuinely empty workspace would indicate a different underlying cause and warrants further investigation rather than the counter-reset fix above.
