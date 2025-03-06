---
title: Entities Managed by decK
description: Understand which entities decK can manage

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/

related_resources:
  - text: All decK documentation
    url: /index/deck/
---

decK manages entity configuration for {{site.base_gateway}}, including all core proxy entities.

It does not manage {{site.base_gateway}} configuration parameters in `kong.conf`, or content and configuration for the Dev Portal.

| Entity                               | Managed by decK? |
| ------------------------------------ | ---------------- |
| Services                             | ✅               |
| Routes                               | ✅               |
| Consumers                            | ✅               |
| Plugins                              | ✅               |
| Certificates                          | ✅               |
| CA Certificates                       | ✅               |
| SNIs                                 | ✅               |
| Upstreams                            | ✅               |
| Targets                              | ✅               |
| Vaults                               | ✅               |
| Keys and key sets                    | ❌               |
| Licenses                             | ❌               |
| Workspaces                           | ✅ <sup>1</sup>  |
| RBAC: roles and endpoint permissions | ✅               |
| RBAC: groups and admins              | ❌               |
| Developers                           | ❌               |
| Consumer groups                      | ✅               |
| Event hooks                          | ❌               |
| Keyring and data encryption          | ❌               |

**\[1\]**: decK can create workspaces and manage entities in a given workspace.
However, decK can't delete workspaces, and it can't update multiple workspaces simultaneously.
See [Manage multiple workspaces](/deck/gateway/workspaces/) for more information.

While deck can manage a majority of {{site.base_gateway}}'s configuration, we recommend additional arrangements for deployment, backup, and restoring unmanaged entities for a more comprehensive approach.
