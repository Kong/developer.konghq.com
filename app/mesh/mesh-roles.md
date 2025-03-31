---
title: Mesh RBAC Roles
content_type: reference
products:
  - gateway
tiers: 
  - enterprise
tools:
    - admin-api
entities:
  - rbac
description: Mesh RBAC roles stub page
schema:
    api: gateway/admin-ee
    path: /schemas/rbac

related_resources:
  - text: Gateway Workspace entity
    url: /gateway/entities/workspace/
  - text: Gateway Vault entity
    url: /gateway/entities/vault/


works_on:
  - on-prem
---

@TODO

## {{site.mesh_product_name}}

Kubernetes provides its own RBAC system but it does not allow you to: 

* Restrict access to a resource on a specific Mesh. 
* Restrict access based on the content of the policy.

{{site.mesh_product_name}} RBAC works on top of Kubernetes providing two globally scoped (not bound to {{site.mesh_product_name}}) resources to aid in implementing RBAC.

<!--vale off-->
{% feature_table %} 
item_title: Mesh RBAC Role
columns:
  - title: Description
    key: description
  - title: Scoped Globally
    key: global_scope

features:
  - title: "`AccessRole`"
    description: |
      Specifies the access and resources that are granted.
    global_scope: true
  - title: "`AccessRoleBinding`"
    description: |
      Assigns a set of `AccessRoles` to a set of objects (users and groups). 
    global_scope: true

{% endfeature_table %}
<!--vale on -->