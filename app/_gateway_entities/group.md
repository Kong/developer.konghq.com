---
title: Groups
content_type: reference
entities:
  - group

description: |
  Groups of RBAC users in Kong Gateway
  
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
  - q: What authentication types work with the Group entitiy?
    a: |
      [Basic-auth](/plugins/basic-auth/), [LDAP](/plugins/ldap-auth),[OIDC](/plugins/oidc/).
---

## What is a Group?


In {{site.base_gateway}}, the Group entity functions as a resource for [RBAC](/gateway/entities/rbac/#role-configuration). {{site.base_gateway}} admins can map permissions and Roles to a Group, and use the Group to simplify role assignment accross the {{site.base_gateway}} environment. The group’s resource can also be used to integrate IDPs like [Okta](/plugins/okta/) with Kong Manager allowing mapping of relationships between your service directory mappings and Kong Manager Roles.


## Service directory mapping

With Service directory mapping, Groups are mapped to [RBAC Roles](/gateway/entities/rbac/#role-configuration/). When a user logs in to Kong Manager, they are identified with their Admin username and authenticated with the user credentials in a service directory, like [LDAP](/plugins/ldap-auth/). The service directory creates a relationship with the associated RBAC Roles that are defined in {{site.base_gateway}}. This follows the following steps: 


1. Roles are created in {{site.base_gateway}}.
2. Groups are created and associated with RBAC Roles
3. Groups are associated with a directory
4. Permissions will be assigned to {{site.base_gateway}} users based on Group assignment.

For more information, read the [LDAP](/plugins/ldap-auth/) documentation.


## Schema

{% entity_schema %}

## Create a group

Creating an RBAC user requires RBAC to be enabled for {{site.base_gateway}}, for instructions on how to do that see [Enable RBAC](/gateway/entities/#enable-rbac).

{% entity_example %}
type: group
data:
  name: my-group
  comment: A description associated with this group.
{% endentity_example %}