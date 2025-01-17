---
title: Groups
content_type: reference
entities:
  - group

description: |
  Groups of RBAC users in {{site.base_gateway}}
  
related_resources:
  - text: RBAC entity
    url: /gateway/entities/rbac/
  - text: Admins entity
    url: /gateway/entities/admin/
  - text: LDAP Authentication
    url: /plugin/ldap-auth
  - text: Workspace
    url: /gateway/entities/workspace/

tier: enterprise

api_specs:
  - gateway/admin-ee

tools:
  - admin-api

schema:
  api: gateway/admin-ee
  path: /schemas/Group

faqs:
  - q: What authentication types work with the Group entity?
    a: |
      [Basic-auth](/plugins/basic-auth/), [LDAP](/plugins/ldap-auth),[OIDC](/plugins/oidc/).
---

## What is a Group?


In {{site.base_gateway}}, the Group entity functions as a resource for [RBAC](/gateway/entities/rbac/#role-configuration). {{site.base_gateway}} Admins can map Permissions and Roles to a Group, and use the Group to simplify Role assignment across the {{site.base_gateway}} environment. 

The Group resource can also be used to integrate identity providers like Okta with Kong Manager, letting you map relationships between your service directory mappings and Kong Manager Roles.


## Service directory mapping

With service directory mapping, Groups can be mapped to [RBAC Roles](/gateway/entities/rbac/#role-configuration/). When a user logs in to Kong Manager, they are identified with their Admin username and authenticated with user credentials from a service directory, like [LDAP](/plugins/ldap-auth/). The service directory creates a relationship with the associated RBAC Roles that are defined in {{site.base_gateway}}. 
This happens in the following order: 


1. Roles are created in {{site.base_gateway}}.
2. Groups are created and associated with RBAC Roles.
3. Groups are associated with an external directory.
4. Permissions are assigned to {{site.base_gateway}} users based on Group assignment.

For more information, read the [LDAP](/plugins/ldap-auth/) documentation.


## Schema

{% entity_schema %}

## Create a group

Creating an RBAC Group requires [RBAC to be enabled](/gateway/entities/rbac/#enable-rbac) for {{site.base_gateway}}.

{% entity_example %}
type: group
data:
  name: my-group
  comment: A description associated with this group.
{% endentity_example %}