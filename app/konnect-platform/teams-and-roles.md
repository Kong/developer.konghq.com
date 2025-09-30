---
title: "{{site.konnect_short_name}} teams and roles"
content_type: reference
layout: reference
breadcrumbs:
  - /konnect/

products:
  - konnect

works_on:
  - konnect

search_aliases: 
  - konnect teams
  - konnect roles
description: "{{site.konnect_short_name}} has the ability to create teams and roles within an organization and use them to distribute permissions."

related_resources:
  - text: "{{site.konnect_short_name}} account, pricing, and organization deactivation"
    url: /konnect-platform/account/
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
  - q: I have the `API Products Publisher` role for the API product I want to publish, why don't I see any classic Dev Portals that I can publish to?
    a: To publish API products to a classic Dev Portal, you need at least a `Viewer` role for Dev Portal in addition to the `API Products Publisher` role.
---

To help secure and govern your environment, {{site.konnect_short_name}} provides
the ability to manage authorization with teams and roles. You can use {{site.konnect_short_name}}'s
predefined teams for a standard set of roles, or create custom teams with
any roles you choose. Invite users and add them to these teams to manage user
access.

You must either be a member of the Organization Admin team, or be assigned the
Identity Admin role, to manage users, teams, and roles.

{:.info}
> **Note:** If the Okta integration is [enabled](/konnect-platform/sso/),
{{site.konnect_short_name}} users and teams become read-only. An organization
admin can view all registered users in {{site.konnect_short_name}}, but cannot
edit their team membership from the {{site.konnect_short_name}} side. To manage
automatically-created users, adjust user permissions through Okta, or
[adjust team mapping](/konnect-platform/sso/).

## Access precedence

Users can be part of any number of teams, and the roles gained from the teams
are additive. For example, if you add a user to both the Service Developer and
Portal Viewer teams, the user can create and manage Services
through API Products _and_ register applications through the Dev Portal.

If two roles provide access to the same [entity](/gateway/entities/), the role with more access
takes effect. For example, if you have the Service Admin and Service Deployer
roles on the same Service, the Service Admin role takes precedence.

## Geographic region assignment

Teams and roles can be assigned to a specific [geographic region](/konnect-platform/geos/) in {{site.konnect_short_name}}. Those teams and roles only access {{site.konnect_short_name}} objects, such as Services, that are also located in the same geo they are assigned to.

## Teams

A team is a group of users with access to the same roles. Teams are useful
for assigning access by functionality, where they can provide granular access to
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
    description: Users can fully manage all entities and configuration in the organization. In addition to users granted the Organization Admin role, each organization also has one Owner, who always has this role and is the only user who can delete the organization.
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

### Create a custom team

Custom teams let organizations manage user access by grouping roles and permissions. 

Any user added to a custom team automatically inherits all roles assigned to that team.

To create and configure a custom team:

1. Create the team  
   Send a `POST` request to the [`/teams` endpoint](/api/konnect/identity/#/operations/create-team) with the `name` and `description` in the request body. Save the `team_id` from the response.

1. Assign roles to the team  
   Send a `POST` request to the [`/assigned-roles` endpoint](/api/konnect/identity/#/operations/teams-assign-role) to grant the team specific roles.

1. Add users to the team  
   To give a user access to the team’s roles, you must assign them to the team.  
   Send a `POST` request to the [`/users` endpoint](/api/konnect/identity/#/operations/add-user-to-team). Users can belong to multiple teams and inherit roles from each.
 
1. (Optional) Enable group-to-team mappings  
   If [single sign-on (SSO)](/konnect-platform/sso/) is enabled, you can configure {{site.konnect_short_name}} to automatically map users to teams based on group claims from your IdP. To do this, send a `PUT` request to the [`/team-mappings` endpoint](/api/konnect/identity/#/operations/update-idp-team-mappings) with `team_ids` in the request body.

## Roles

Roles predefine access to a particular resource, or
instances of a particular resource type (for example, API product roles can be scoped to a particular API product or all API products while Control Plane roles can be scoped to a particular Control Plane or all Control Planes).

You can manage a user's roles by navigating to [**Organization**](https://cloud.konghq.com/organization/) > **Users** in {{site.konnect_short_name}} and clicking the **Role Assignments** tab for a user.

### Predefined roles

{{site.konnect_short_name}} provides the following predefined roles.

#### Analytics

{% include_cached konnect/analytics-roles.md %}


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
  - role: "`Network Admin`"
    description: Access to all read and write permissions related to a network.
  - role: "`Network Creator`"
    description: Access to creating networks.
  - role: "`Network Viewer`"
    description: Access to read-only permissions to networks.
{% endtable %}

#### {{site.konnect_catalog}}

The following describes the predefined roles for {{site.konnect_catalog}}:
 
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: "`Integration Admin`"
    description: Can view and edit all integrations (install/authorize).
  - role: "`Integration Viewer`"
    description: Access to read-only permissions to integrations.
  - role: "`Scorecard Viewer`"
    description: Access read-only permissions related to Scorecards.
  - role: "`Scorecard Admin`"
    description: Can view and edit a select list of {{site.konnect_catalog}} services, map resources to those services, manage all resources, and has read-only access to all integrations and integration instances.
  - role: "`Service Admin`"
    description: Can view and edit a select list of services, map resources to those services, and manage all resources and discovery rules.
  - role: "`Service Creator`"
    description: |
      Can create new {{site.konnect_catalog}} services, becomes the Service Admin for any service they create, and can view and edit all resources. 
      Includes read-only access to all integrations and integration instances.
      <br><br>This role does not grant access to _existing_ services or their configurations. See the `Service Admin` role. 
      <br><br>This role does not grant write access to integration instances. See the `Integration Admin` role.
  - role: "`Service Viewer`"
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
  - role: "`Admin`"
    description: Owner of an existing Dev Portal instance. The owner has full write access related to any developers and applications in the organization.
  - role: "`Appearance Maintainer`"
    description: Access the Portal instance and edit its appearance.
  - role: "`Creator`"
    description: Create new Portals.
  - role: "`Maintainer`"
    description: Edit, view, and delete Dev Portal applications, and view developers.
  - role: "`Product Publisher`"
    description: Manage publishing products to a Dev Portal.
  - role: "`Viewer`"
    description: Read-only access to Dev Portal developers and applications.
  - role: "`API Registration Approver`"
    description: Can approve Dev Portal application registrations.
  - role: "`Content Editor`"
    description: Edits Dev Portal pages, snippets, and customization.
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
  - role: "`Creator`"
    description: Create new app auth strategies.
  - role: "`Maintainer`"
    description: Edit one or all app auth strategies.
  - role: "`Viewer`"
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
  - role: "`Creator`"
    description: Create new DCR providers.
  - role: "`Maintainer`"
    description: Edit one or all DCR providers.
  - role: "`Viewer`"
    description: Read-only access to one or all DCR providers.
{% endtable %}

