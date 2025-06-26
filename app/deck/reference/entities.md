---
title: Entities managed by decK
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
  - text: "{{site.base_gateway}} entities"
    url: /gateway/entities/
---

decK manages entity configuration for {{site.base_gateway}}, including all core proxy entities.

It does not manage {{site.base_gateway}} configuration parameters in `kong.conf`, or content and configuration for the Dev Portal.

{% feature_table %}
item_title: Entity
columns:
  - title: Managed by decK?
    key: managed

features:
  - title: Services
    managed: true
  - title: Routes
    managed: true
  - title: Consumers
    managed: true
  - title: Plugins
    managed: true
  - title: Certificates
    managed: true
  - title: CA Certificates
    managed: true
  - title: SNIs
    managed: true
  - title: Upstreams
    managed: true
  - title: Targets
    managed: true
  - title: Vaults
    managed: true
  - title: |
      Keys and Key Sets {% new_in 1.48 %}
    managed: true
  - title: Licenses
    managed: false
  - title: Workspaces <sup>1</sup>
    managed: true
  - title: RBAC roles and endpoint permissions
    managed: true
  - title: RBAC groups and admins
    managed: false
  - title: Developers
    managed: false
  - title: Consumer Groups
    managed: true
  - title: Event hooks
    managed: false
  - title: Keyring and data encryption
    managed: false
  - title: Partials
    managed: true

{% endfeature_table %}

{:.info}
> **\[1\]**: decK can create workspaces and manage entities in a given workspace.
However, decK can't delete workspaces, and it can't update multiple workspaces simultaneously.
See [Manage multiple workspaces](/deck/gateway/workspaces/) for more information.

While decK can manage a majority of {{site.base_gateway}}'s configuration, we recommend [additional arrangements](/gateway/upgrade/backup-and-restore/) for deployment, backup, and restoring unmanaged entities for a more comprehensive approach.
