---
title: Cannot delete a workspace after enabling the Developer Portal
content_type: support
description: Enabling the Developer Portal seeds a workspace with Pages, Partials, and Specs entities that must be deleted (along with associated `rbac_roles`) before the workspace can be removed.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why can't I delete a workspace after enabling the Developer Portal?
  a: |
    Enabling the Developer Portal creates default Pages, Partials, and Specs entities in the workspace, and these (along with any Developer Portal `rbac_roles`) must be deleted before the workspace can be removed. Re-enable the Portal so you can see and delete them, either one at a time or in bulk with the `kong-portal-cli` tool's `portal wipe <workspace_name>` command.
related_resources:
  - text: "`kong-portal-cli` tool"
    url: https://github.com/kong/kong-portal-cli
  - text: "`kong-portal-templates` repository"
    url: https://github.com/Kong/kong-portal-templates
---

## Problem

After the Developer Portal is enabled, it is not possible to delete a workspace as it is not empty. Even disabling the Developer Portal does not allow the workspace to be deleted. An error message is shown that `files` and `rbac_roles` exist;

## Cause

When enabling the Developer Portal, the default set of Pages, Partials and Specs are created. These entities need to be deleted to empty the Workspace before the workspace can be deleted.

## Solution

To delete the entities, there are two options, both of these first require you to re-enable the Developer Portal so that the list of Pages, Partials and Specs can be viewed. Follow either option below;

Note: on Kong Gateway (Enterprise) 3.11.0.0 and later, the on-prem/Gateway-native Developer Portal is hard-deprecated and gated behind a separate, support-provided `portal_and_vitals_key` license extra. Without that key, every Portal-dependent Admin API route (`/files`, `/<workspace>/files`, `/specs`, etc.) returns a flat 404 regardless of the workspace's `config.portal` setting — so on a standard Enterprise license, enabling the Developer Portal for a workspace will not actually create any Pages/Partials/Specs entities in the first place, and this specific "workspace won't delete because Dev Portal files exist" scenario should not occur today. If you do hit it, your license likely already carries the `portal_and_vitals_key` extra, and the removal steps below remain valid.

1. Manually delete each entity until all of them have been removed
2. Use the `kong-portal-cli` tool — the deployment tooling for the template files in the separate `kong-portal-templates` repository. Follow the steps to install this utility and use a command similar to below to delete all the Developer Portal entities in one go;

```bash

portal wipe <workspace_name>
```

To delete the roles, refer to the KB below;

[Cannot delete an empty workspace](/support/cannot-delete-an-empty-workspace/)
