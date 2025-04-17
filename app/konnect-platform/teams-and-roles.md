---
title: "{{site.konnect_short_name}} teams and roles"
content_type: reference
layout: reference

products:
    - gateway

works_on:
  - konnect

description: Explains which teams and roles {{site.konnect_short_name}} has and how to manage them.

related_resources:
  - text: "{{site.konnect_short_name}} Account, Pricing, and Organization Deactivation"
    url: /konnect-platform/konnect-account/
faqs:
  - q: What is required to manage users, teams, and roles in {{site.konnect_short_name}}?
    a: You must be part of the **Organization Admin team** to manage users, teams, and roles.
  - q: What is a team in {{site.konnect_short_name}}?
    a: A team is a group of users with access to the same roles. Teams allow assigning access to {{site.konnect_short_name}} resources based on roles.
  - q: What is a role in {{site.konnect_short_name}}?
    a: |
      A role defines predefined access to a particular resource or instances of a resource type. For example, API product roles can be scoped to a specific API product or all API products, while Control Plane roles can be scoped to a specific Control Plane or all Control Planes.
  - q: Can predefined teams in {{site.konnect_short_name}} be modified or deleted?
    a: No, predefined teams have fixed role sets that cannot be modified or deleted.
---

To help secure and govern your environment, {{site.konnect_short_name}} provides
the ability to manage authorization with teams and roles. You can use {{site.konnect_short_name}}'s
predefined teams for a standard set of roles, or create custom teams with
any roles you choose. Invite users and add them to these teams to manage user
access.

You must be part of the Organization Admin team to manage users, teams, and
roles.

{:.info}
> **Note:** If the Okta integration is [enabled](/konnect-platform/konnect-sso/),
{{site.konnect_short_name}} users and teams become read-only. An organization
admin can view all registered users in {{site.konnect_short_name}}, but cannot
edit their team membership from the {{site.konnect_short_name}} side. To manage
automatically-created users, adjust user permissions through Okta, or
[adjust team mapping](/konnect-platform/konnect-sso/).

## Access precedence

Users can be part of any number of teams, and the roles gained from the teams
are additive. For example, if you add a user to both the Service Developer and
Portal Viewer teams, the user can create and manage Services
through API Products _and_ register applications through the Dev Portal.

If two roles provide access to the same [entity](/gateway/entities/), the role with more access
takes effect. For example, if you have the Service Admin and Service Deployer
roles on the same Service, the Service Admin role takes precedence.

## Geographic region assignment

Teams and roles can be assigned to a specific [geographic region](/konnect-geos/) in {{site.konnect_short_name}}. Those teams and roles only access {{site.konnect_short_name}} objects, such as services, that are also located in the same geo they are assigned to.

## Teams

A team is a group of users with access to the same roles. Teams are useful
for assigning access by functionality, they can provide granular access to
any group of {{site.konnect_short_name}} resources based on roles.

You can create and manage teams by navigating to [**Organization**](https://cloud.konghq.com/organization/) > **Teams** in {{site.konnect_short_name}}.

### Predefined teams

All new and existing organizations in {{site.konnect_short_name}} have predefined default teams. The default teams can't be modified or deleted.

{% table %}
columns:
  - title: Team
    key: team
  - title: Description
    key: description
rows:
  - team: Analytics Admin
    description: Users can fully manage all [Analytics](/advanced-analytics/) content, which includes creating, editing, and deleting reports, as well as viewing the analytics summary.
  - team: Analytics Viewer
    description: Users can view the [Analytics](/advanced-analytics/) summary and report data.
  - team: Organization Admin
    description: Users can fully manage all entities and configuration in the organization.
  - team: Organization Admin (Read Only)
    description: Users can view all entities and configuration in the organization.
  - team: Portal Admin
    description: Users can fully manage all Dev Portal content, which includes {{site.konnect_short_name}} service pages and supporting content, as well as Dev Portal configuration and Service connections. <br> To manage app registration requests, members must also be assigned to the Admin or Maintainer roles for the corresponding Services.
  - team: API Product Admin
    description: Users can create and manage API products, including publishing API product versions to Dev Portal and enabling application registration.
  - team: API Product Developer
    description: Users can create and manage versions of API products.
  - team: Control Plane Admin
    description: Users can create and manage Control Planes.
{% endtable %} 

## Roles

Roles predefine access to a particular resource, or
instances of a particular resource type (for example, API product roles can be scoped to a particular API product or all API products while Control Plane roles can be scoped to a particular Control Plane or all Control Planes).

You can manage a user's roles by navigating to [**Organization**](https://cloud.konghq.com/organization/) > **Users** in {{site.konnect_short_name}} and clicking the **Role Assignements** tab for a user.

### Predefined roles

{{site.konnect_short_name}} provides the following predefined roles.

#### API Products

The following describes the predefined roles for API Products:

<!-- vale off -->
{% konnect_roles_table %}
schema: api_products
{% endkonnect_roles_table %}
<!-- vale on -->

#### Control Planes

The following describes the predefined roles for Control Planes:

<!-- vale off -->
{% konnect_roles_table %}
schema: control_planes
{% endkonnect_roles_table %}
<!-- vale on -->

#### Audit logs

The following describes the predefined roles for audit logs:

<!-- vale off -->
{% konnect_roles_table %}
schema: audit_logs
{% endkonnect_roles_table %}
<!-- vale on -->

#### Identity

The following describes the predefined roles for identity:

<!-- vale off -->
{% konnect_roles_table %}
schema: identity
{% endkonnect_roles_table %}
<!-- vale on -->

#### Mesh control planes

The following describes the predefined roles for Mesh:

<!-- vale off -->
{% konnect_roles_table %}
schema: mesh_control_planes
{% endkonnect_roles_table %}
<!-- vale on -->

#### Networks 

The following describes the predefined roles for networks:

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: Network Admin 
    description: Access to all read and write permissions related to a network.
  - role: Network Creator
    description: Access to creating networks.
  - role: Network Viewer
    description: Access to read-only permissions to networks.
{% endtable %}

#### Service Catalog

The following describes the predefined roles for Service Catalog:
 
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: Discovery Admin
    description: Access to all read and write permissions related to service discoveries.
  - role: Discovery Viewer
    description: Access to read-only permissions related to service discoveries.
  - role: Integration Admin
    description: Can view and edit all integrations (install/authorize).
  - role: Integration Viewer
    description: Access to read-only permissions to integrations.
  - role: Service Admin
    description: Can view and edit a select list of services, map resources to those services, and manage all resources and discovery rules.
  - role: Service Creator
    description: Can create new services, becomes the service admin for any service they create, and can view, edit, and create all resources and discovery rules.
  - role: Service Viewer
    description: Can view a select list of services and all resources and discovery rules.
{% endtable %}

#### Dev Portal

The following describes the predefined roles for Dev Portal:

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: Admin
    description: Owner of an existing Dev Portal instance. The owner has full write access related to any developers and applications in the organization.
  - role: Appearance Maintainer
    description: Access the Portal instance and edit its appearance.
  - role: Creator
    description: Create new Portals.
  - role: Maintainer
    description: Edit, view, and delete Dev Portal applications, and view developers.
  - role: Product Publisher
    description: Manage publishing products to a Dev Portal.
  - role: Viewer
    description: Read-only access to Dev Portal developers and applications.
{% endtable %}

#### Application auth strategies

The following describes the predefined roles for application auth strategies:

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: Creator
    description: Create new app auth strategies.
  - role: Maintainer
    description: Edit one or all app auth strategies.
  - role: Viewer
    description: Read-only access to one or all app auth strategies.
{% endtable %}


#### DCR

The following describes the predefined roles for dynamic client registration (DCR):

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: Creator
    description: Create new DCR providers.
  - role: Maintainer
    description: Edit one or all DCR providers.
  - role: Viewer
    description: Read-only access to one or all DCR providers.
{% endtable %}

