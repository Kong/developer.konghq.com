---
title: Entities Managed by decK

description: "decK manages entity configuration for{{site.base_gateway}}, including all core proxy entities."

content_type: reference
layout: reference

works_on:
    - on-prem
    - konnect

products:
  - api-ops

tools:
  - deck

breadcrumbs:
  - /deck/
---


decK manages entity configuration for {{site.base_gateway}}, including all core proxy entities.

It does not manage {{site.base_gateway}} configuration parameters in `kong.conf`, or content and configuration for the Dev Portal. decK can create Workspaces and manage entities in a given Workspace. 
However, decK can't delete Workspaces, and it can't update multiple Workspaces simultaneously.
See the [Workspace](/gateway/entities/workspace) documentation for more information. 


## Managed entities
{% feature_table %}
columns:
  - title: Managed by decK
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
  - title: Keys and key sets
    managed: false
  - title: Licenses
    managed: false
  - title: Workspaces
    managed: true
  - title: RBAC roles and endpoint permissions
    managed: true
  - title: RBAC groups and admins
    managed: false
  - title: Developers
    managed: false
  - title: Consumer groups
    managed: false
  - title: Event hooks
    managed: false
  - title: Keyring and data encryption
    managed: false
   
{% endfeature_table %}

{:.info}
> decK doesn't manage documents (`document_objects`) related to Services. That means they will not be included when performing a `deck gateway dump` or `deck gateway sync` action. If you attempt to delete a service that has an associated document via decK, it will fail.
