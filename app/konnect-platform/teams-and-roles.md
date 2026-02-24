---
title: "{{site.konnect_short_name}} teams and roles"
content_type: reference
layout: reference
breadcrumbs:
  - /konnect/

toc_depth: 4
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
  - q: My team has a Dev Portal, why can't I see APIs?
    a: You need additional permissions to see APIs. See the [Catalog APIs roles](/konnect-platform/teams-and-roles/#catalog-apis) for more information.
  - q: Why can't my users create dashboards even though they have the Dashboard Creator, Admin, or Editor role?
    a: | 
      {% include konnect/faqs/roles.md %}
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
    description: Users can fully manage all [Analytics](/observability/) content, which includes creating, editing, and deleting reports, as well as viewing the analytics summary. They also have [roles](#observability) for Dashboard Creator, Dashboard Admin (for all instances), Report Creator, and Report Admin (for all instances). 
  - team: Analytics Viewer
    description: Users can view the [Analytics](/observability/) summary and report data. They also have [roles](#observability) for Dashboard Viewer and Report Viewer for all instances.
  - team: Organization Admin
    description: Users can fully manage all entities and configuration in the organization. In addition to users granted the Organization Admin role, each organization also has one Owner, who always has this role and is the only user who can delete the organization.
  - team: Organization Admin (Read Only)
    description: Users can view all entities and configuration in the organization.
  - team: Portal Admin
    description: Users can fully manage all Dev Portal content, which includes {{site.konnect_short_name}} service pages and supporting content, as well as Dev Portal configuration and Service connections. <br> To manage app registration requests, members must also be assigned to the Admin or Maintainer roles for the corresponding Services.
  - team: API Product Admin
    description: |
      Users can create and manage API products, including publishing API product versions to Dev Portal and enabling application registration.

      {:.warning}
      > API Product roles only apply to classic Dev Portals (v2). We recommend [migrating to the new Dev Portal (v3)](/dev-portal/v2-migration/) and using [Catalog API roles](/konnect-platform/teams-and-roles/#catalog-apis) instead.
  - team: API Product Developer
    description: |
      Users can create and manage versions of API products.

      {:.warning}
      > API Product roles only apply to classic Dev Portals (v2). We recommend [migrating to the new Dev Portal (v3)](/dev-portal/v2-migration/) and using [Catalog API roles](/konnect-platform/teams-and-roles/#catalog-apis) instead.
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

#### Dev Portal custom teams

You can use custom {{site.konnect_short_name}} to create Dev Portal teams for common Dev Portal personas. The following table details the Dev Portal roles you can assign to each custom team:

<!--vale off-->
{% table %}
columns:
  - title: Persona
    key: persona
  - title: Custom team description
    key: description
  - title: Dev Portal roles
    key: roles
rows:
  - persona: "API Platform Owner"
    description: |
      An API Platform Owner has full access to create, configure, and delete resources related to APIs, Portals, and Applications.
    roles: |
      * Portal Creator
      * Portal Admin 
      * Application Auth Strategy Creator
      * Application Auth Strategy Maintainer 
      * DCR Provider Creator
      * DCR Provider Maintainer 
      * API Creator
      * API Admin 
      * API Publisher 
  - persona: "API Security Owner"
    description: |
      An API Security Owner can create, update, and delete auth strategies used between APIs and Applications.
    roles: |
      * Application Auth Strategy Creator
      * Application Auth Strategy Maintainer 
      * DCR Provider Creator
      * DCR Provider Maintainer 
  - persona: Portal Owner
    description: |
      A Portal Owner has full access to configure a Dev Portal and manage applications in a Dev Portal.
    roles: |
      * Portal Admin for a specific Dev Portal 
      * Application Auth Strategy Viewer for a specific auth strategy
      * API Viewer for APIs they can approve access to
      * (optional) API Publisher for specific APIs
  - persona: Portal Maintainer
    description: |
      A Portal Maintainer has full access to configure a Dev Portal and manage applications in a Dev Portal. 
      They cannot delete the Dev Portal.
    roles: |
      * Portal Admin for a specific Dev Portal
      * Application Auth Strategy Viewer for a specific auth strategy
      * API Viewer for APIs they can approve access to
      * (optional) API Publisher for specific APIs
  - persona: API Owner
    description: |
      An API Owner has full access to define, configure, and publish an API to Dev Portal(s) and approve registrations for the API.
    roles: |
      * Application Auth Strategy Viewer for a specific auth strategy
      * API Admin for specific APIs
      * API Publisher for specific APIs
      * API Approver for specific APIs
      * Portal Viewer {portalId} (for Dev Portals they can publish or approve registrations in)
  - persona: API Maintainer
    description: |
      An API Maintainer has full access to define, configure, and publish an API to Dev Portal(s) and approve registrations for the API.
      They cannot delete the API.
    roles: |
      * Application Auth Strategy Viewer for a specific auth strategy
      * API Maintainer for specific APIs
      * API Publisher for specific APIs
      * API Approver for specific APIs
      * Portal Viewer for a specific Dev Portal
  - persona: Portal Content Editor
    description: |
      The Portal Content Editor can create, update, and delete pages and other content in a Dev Portal.
    roles: |
      Portal Content Editor for a specific Dev Portal
{% endtable %}
<!--vale on-->

## Roles

Roles predefine access to a particular resource, or
instances of a particular resource type (for example, Catalog API roles can be scoped to a particular API or all APIs while Control Plane roles can be scoped to a particular Control Plane or all Control Planes).

You can manage a user's roles by navigating to [**Organization**](https://cloud.konghq.com/organization/) > **Users** in {{site.konnect_short_name}} and clicking the **Role Assignments** tab for a user.

### Predefined roles

{{site.konnect_short_name}} provides the following predefined roles.

{:.info}
> **Note:** To publish API products to a classic Dev Portal, you need at least a `Viewer` role for Dev Portal in addition to the `API Products Publisher` role.

#### Application auth strategies

The following table describes the predefined roles for [application auth strategies](/dev-portal/auth-strategies/):

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Creator`"
    description: Create new app auth strategies.
    permissions: |
      * Create auth strategies.
      * Read and list auth strategies.
  - role: "`Maintainer`"
    description: Edit one or all app auth strategies.
    permissions: |
      * Edit, delete, read, and list auth strategies.
  - role: "`Viewer`"
    description: Read-only access to one or all app auth strategies.
    permissions: |
      * Read and list auth strategies.
{% endtable %}
<!--vale on-->

#### Auth servers

The following table describes the predefined roles for [Kong Identity](/kong-identity/) authorization servers:

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Admin`"
    description: Access to all read and write permissions related to an Authorization Server.
    permissions: |
      * Create, edit, delete, read, and list auth servers.
  - role: "`Viewer`"
    description: Access to all read permissions related to an Authorization Server.
    permissions: |
      * Read and list auth servers.
{% endtable %}

#### APIs

The following table describes the predefined roles for [Catalog APIs](/catalog/apis/). Read, edit, and delete access is granted per-API. Only the create and list permissions are granted at the org level.

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Creator`"
    description: Access to create new API in Konnect. The creator becomes an admin of the API they create.
    permissions: |
      * Create and list APIs.
  - role: "`Admin`"
    description: Admin of an existing API, providing ability to read and edit configuration, view API analytics, and delete the API.
    permissions: |
      * Read, edit, delete, and list APIs.
  - role: "`Maintainer`"
    description: Access to read and edit configuration of an API and view analytics of an API.
    permissions: |
      * Read, edit, and list APIs.
  - role: "`Viewer`"
    description: Read-only access to an API configuration and analytics.
    permissions: |
      * Read and list APIs.
  - role: "`Publisher`"
    description: Access to publish an API to visible portals.
    permissions: |
      * Read, list, and publish APIs.
  - role: "`Registration Approver`"
    description: Access to approve an API registration request.
    permissions: |
      * Read, list, and grant access to APIs.
{% endtable %}
<!--vale on-->

#### Audit logs

The following table describes the predefined roles for [audit logs](konnect-platform/audit-logs/):

<!--vale off-->
{% konnect_roles_table %}
schema: audit_logs
{% endkonnect_roles_table %}
<!--vale on-->

#### {{site.konnect_catalog}}

The following table describes the predefined roles for [{{site.konnect_catalog}}](/catalog/):

<!--vale off--> 
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Integration Admin`"
    description: Can view and edit all integrations (install/authorize).
    permissions: |
      * Read, list, create, edit, and delete integrations.
      * Read, list, create, and delete auth credentials.
  - role: "`Integration Viewer`"
    description: Access to read-only permissions to integrations.
    permissions: |
      * Read and list integrations.
      * Read and list integration auth credentials.
  - role: "`Scorecard Viewer`"
    description: Access read-only permissions related to Scorecards.
    permissions: |
      * Read and list integrations.
      * Read and list integration auth credentials.
      * List criteria templates.
      * Read and list scorecards.
  - role: "`Scorecard Admin`"
    description: Can view and edit a select list of {{site.konnect_catalog}} services, map resources to those services, manage all resources, and has read-only access to all integrations and integration instances.
    permissions: |
      * Read and list integrations.
      * Read and list integration auth credentials.
      * List scorecard and criteria templates.
      * List, read, create, edit, and delete scorecards.
  - role: "`Service Admin`"
    description: Can view and edit a select list of services, map resources to those services, and manage all resources and discovery rules.
    permissions: |
      * Read, edit, delete, and list {{site.konnect_catalog}} services.
      * Read and list integrations.
      * Read and list integration auth credentials.
      * Create, edit, read, delete, and list documents.
      * Create, edit, read, delete, list, and preview API specs.
      * List and read events.
      * Create, edit, read, delete, and list resources.
      * List and read scorecards.
      * List criteria templates.
  - role: "`Service Creator`"
    description: |
      Can create new {{site.konnect_catalog}} services, becomes the Service Admin for any service they create, and can view and edit all resources. 
      Includes read-only access to all integrations and integration instances.
      <br><br>This role does not grant access to _existing_ services or their configurations. See the `Service Admin` role. 
      <br><br>This role does not grant write access to integration instances. See the `Integration Admin` role.
    permissions: |
      * Create and list {{site.konnect_catalog}} services.
      * Read and list integrations.
      * Read and list integration auth credentials.
      * Edit, read, and list resources.
      * List and read scorecards.
      * List criteria templates.
  - role: "`Service Viewer`"
    description: Can view a select list of services and all resources and discovery rules.
    permissions: |
      * Read and list {{site.konnect_catalog}} services.
      * Read and list integrations.
      * Read and list integration auth credentials.
      * Read and list documents.
      * Read and list API specs.
      * Read and list events.
      * Create, edit, read, delete, and list resources.
      * List and read scorecards.
      * List criteria templates.
{% endtable %}
<!--vale on-->

#### Control planes

The following table describes the predefined roles for control planes:

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Admin`"
    description: "This role grants full write access to all entities within a control plane."
    permissions: |
      * Create, read, list, edit, and delete control planes and all configurations within them.
  - role: "`Certificate Admin`"
    description: "This role grants full write access to administer certificates."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list certificates.
      * Create, read, edit, delete, and list CA certificates.
  - role: "`Cloud Gateway Cluster Admin`"
    description: "Access to all read and write permissions related to cloud-gateways configurations and custom domains."
    permissions: |
      * Create, read, list, and delete Cloud Gateway configurations.
      * Create, read, list, and delete custom domains.
  - role: "`Cloud Gateway Cluster Viewer`"
    description: "Access to read-only permissions to cloud-gateways configurations and custom domains."
    permissions: |
      * Read and list Cloud Gateway configurations.
      * Read and list custom domains.
  - role: "`Consumer Admin`"
    description: "This role grants full write access to administer consumers."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list Consumers.
      * Read and list Partials.
  - role: "`Creator`"
    description: "Creates a new Control Plane in an organization. The creator becomes the owner of the Control Plane they create."
    permissions: |
      * Create and list control planes.
  - role: "`Deployer`"
    description: "This role grants full write access to administer services, routes and plugins necessary to deploy services in Service Catalog."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list plugins and custom plugins.
      * Create, read, edit, delete, and list Routes.
  - role: "`Event Gateways Creator`"
    description: "Access to create a new event gateway in Event Gateway Manager. The creator becomes the owner of the event gateway they create, gaining admin access to the new event gateway. This role does not grant access to existing event gateways, their runtime instances, or their configurations."
    permissions: |
      * Create and list Event Gateways.
  - role: "`Event Gateways Admin`"
    description: "Owner of an existing event gateway. The owners have all write access related to an event gateway, the gateway's runtime instances, and its configuration."
    permissions: |
      * Create, edit, read, list, and delete existing Event Gateways and all of their configurations.
  - role: "`Event Gateways Viewer`"
    description: "Read-only access to all the configurations of an event gateway and its runtime instances."
    permissions: |
      * Read and list Event Gateways and all of their configurations.
  - role: "`Gateway Service Admin`"
    description: "This role grants full write access to administer gateway services."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list plugins and custom plugins.
      * Create, read, edit, delete, and list Partials.
  - role: "`Key Admin`"
    description: "Full write access to administer keys."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list keys.
  - role: "`KNEP Config Admin` (deprecated)"
    description: "*(Legacy permission for Event Gateways)* Full write access to administer Kong Native Event Proxy (KNEP) declarative configuration."
    permissions: |
      * Create, read, list, and delete Kong Native Event Proxy configurations.
  - role: "`KNEP Node` (deprecated)"
    description: "*(Legacy permission for Event Gateways)* Read-only access to Kong Native Event Proxy (KNEP) configuration and write access to KNEP nodes."
    permissions: |
      * Read and list, and delete Kong Native Event Proxy configurations.
  - role: "`Plugin Admin`"
    description: "This role grants full write access to administer plugins."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list plugins and custom plugins.
      * Create, read, edit, delete, and list Partials.
  - role: "`Route Admin`"
    description: "This role grants full write access to administer routes."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list plugins and custom plugins.
      * Create, read, edit, delete, and list Routes.
      * Create, read, edit, delete, and list Partials.
  - role: "`Serverless Cluster Admin`"
    description: "Access to all read and write permissions related to serverless cloud-gateways configurations."
    permissions: |
      * Create, read, list, and delete Serverless Gateway configurations.
  - role: "`Serverless Cluster Viewer`"
    description: "Access to read-only permissions related to serverless cloud-gateways configurations."
    permissions: |
      * Read and list Serverless Gateway configurations.
  - role: "`SNI Admin`"
    description: "This role grants full write access to administer SNIs."
    permissions: |
      * List and read control planes.
      * List and read certificates.
      * Create, read, edit, delete, and list SNIs.
  - role: "`Upstream Admin`"
    description: "This role grants full write access to administer upstreams."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list Upstreams.
      * Create, read, edit, delete, and list Targets.
      * List certificates.
  - role: "`Vault Admin`"
    description: "Full write access to administer Vaults."
    permissions: |
      * List and read control planes.
      * Create, read, edit, delete, and list Vaults.
      * Create, read, edit, delete, and list config stores.
  - role: "`Viewer`"
    description: "This role grants read only access to all entities within a control plane."
    permissions: |
      * Read and list control planes and all configurations within them.
{% endtable %}
<!--vale on-->

#### Dashboards

The following table describes the predefined roles for [{{site.observability}} dashboards](/observability/#dashboard):

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Admin`"
    description: Allows users to edit, delete, and share a Dashboard in Konnect Analytics.
    permissions: |
      * List, read, edit, and delete dashboards.
  - role: "`Creator`"
    description: Allows users to create a new Dashboard in Konnect Analytics.
    permissions: |
      * Create and list dashboards.
  - role: "`Editor`"
    description: Allows users to edit a Dashboard in Konnect Analytics.
    permissions: |
      * List, edit, and read dashboards.
  - role: "`Viewer`"
    description: Allows users to view a Dashboard in Konnect Analytics.
    permissions: |
      * List and read dashboards.
{% endtable %}
<!--vale on-->

#### DCR

The following table describes the predefined roles for [dynamic client registration (DCR)](/dev-portal/dynamic-client-registration/):

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Creator`"
    description: Create new DCR providers.
    permissions: |
      * Create and read DCR providers
  - role: "`Maintainer`"
    description: Edit one or all DCR providers.
    permissions: |
      * Edit, delete, and read DCR providers
  - role: "`Viewer`"
    description: Read-only access to one or all DCR providers.
    permissions: |
      * Read DCR providers
{% endtable %}
<!--vale on-->

#### Identity

The following table describes the predefined roles for identity:

<!--vale off-->
{% konnect_roles_table %}
schema: identity
{% endkonnect_roles_table %}
<!--vale on-->

#### MCP registry

The following table describes the predefined roles for [MCP registries](/catalog/mcp-registry/):

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Admin`"
    description: Admin of an existing MCP registry, providing ability to read and edit configuration, view MCP registry analytics, and delete the MCP registry.
    permissions: |
      * List, read, edit, and delete MCP registries.
      * Create, edit, list, read, and delete MCP server versions.
  - role: "`Creator`"
    description: |
      Access to create new registries and server versions in Konnect. 
      The creator becomes an admin of the registry they create.
    permissions: |
      * Create and list MCP registries.
      * Create, edit, list, and read MCP server versions.
  - role: "`Publisher`"
    description: Access to publish MCP server versions to a registry.
    permissions: |
      * List and read MCP registries.
      * Create, edit, list, and read MCP server versions.
  - role: "`Viewer`"
    description: Read-only access to an MCP registry configuration.
    permissions: |
      * List and read MCP registries.
      * List and read MCP server versions.
{% endtable %}
<!--vale on-->

#### Mesh control planes

The following table describes the predefined roles for {{site.mesh_product_name}}:

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Admin`"
    description: "This role grants full write access to the related to Mesh control planes."
    permissions: |
      * Create, list, read, update, delete, and connect zones for Mesh control planes.
  - role: "`Connector`"
    description: "This role grants a mesh zone to connect to the mesh control plane in Konnect."
    permissions: |
      * Connect zones.
  - role: "`Creator`"
    description: "This role grants access to create new Mesh control planes."
    permissions: |
      * List and create Mesh control planes.
  - role: "`Viewer`"
    description: "This role grants access to read-only permissions to Mesh control planes."
    permissions: |
      * Read and list Mesh control planes.
{% endtable %}
<!--vale on-->

#### {{site.metering_and_billing}}

The following table describes the predefined roles for [{{site.metering_and_billing}}](/metering-and-billing/):

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Ingest`"
    description: "Ingests events only (intended only for machines)."
    permissions: |
      * Ingest events.
  - role: "`Admin`"
    description: "Can read and write every resource. Includes billing apps, billing profiles, and notifications."
    permissions: |
      * Create, list, read, query, update, and delete every resource.
  - role: "`Metering Admin`"
    description: "Can write any metering resources (includes meters and events)."
    permissions: |
      * List, read, and query meters.
      * List events.
  - role: "`Metering Viewer`"
    permissions: |
      * Create, list, read, query, update, and delete meters.
      * List and ingest events.
    description: "Can read any metering resources (includes meters and events)."
  - role: "`Product Catalog Admin`"
    description: "Can write any Product Catalog resources (includes plans, features, and rate cards)."
    permissions: |
      * Create, list, read, and delete features.
      * Create, list, read, update, delete, publish, and archive plans.
      * Create, list, read, update, delete, publish, and archive add-ons.
  - role: "`Product Catalog Viewer`"
    description: "Can read any Product Catalog resources (includes plans, features, and rate cards)."
    permissions: |
      * List and read features.
      * List and read plans.
      * List and read add-ons.
  - role: "`Billing Admin`"
    description: "Can read and write customer, subscription, entitlement, and invoice resources."
    permissions: |
      * Create, list, read, update, delete, and migrate subscriptions and their add-ons.
      * Create, list, read, update, and delete customers.
      * Create, list, read, update, delete, and trigger events on invoices.
      * Create, list, read, update, and delete billing profiles.
      * Create, list, read, update, and delete entitlements.
  - role: "`Billing Viewer`"
    description: "Can read customer, subscription, entitlement, and invoice resources."
    permissions: |
      * Read and list subscriptions and their add-ons.
      * Read and list customers.
      * Read and list and trigger events on invoices.
      * Read and list billing profiles.
      * Read and list entitlements.
{% endtable %}
<!--vale on-->

#### Networks 

The following table describes the predefined roles for [Dedicated Cloud Gateway](/dedicated-cloud-gateways/) networks:

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Network Admin`"
    description: Access to all read and write permissions related to a network.
    permissions: |
      * Read and list provider accounts.
      * Read, list, edit, and delete networks.
      * Attach transit gateways and data plane groups for networks.
      * Create, edit, read, delete, and list transit gateways.
      * Create, edit, read, delete, and list private DNS configs.
  - role: "`Network Creator`"
    description: Access to creating networks.
    permissions: |
      * Deploy, read, and list provider accounts.
      * Create networks.
  - role: "`Network Viewer`"
    description: Access to read-only permissions to networks.
    permissions: |
      * Read and list provider accounts.
      * Read, list, and connect data plane groups for networks.
      * Read and list transit gateways.
{% endtable %}
<!--vale on-->

#### Portals

The following table describes the predefined roles for [Dev Portal](/dev-portal/):

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Admin`"
    description: |
      Owner of an existing Dev Portal instance. The owner has full write access related to any developers and applications in the organization.
      <br><br>

      {:.warning}
      > This role has the ability to approve, revoke, and delete application registrations.
    permissions: |
      * Read, edit, list and delete Dev Portals
      * List, create, read, edit, and delete applications
      * List, create, read, edit, and delete developers
      * Create, edit, delete, read, and list teams
      * Add and remove a role to teams, list roles in teams
      * Add, remove, and list developers from teams
      * Create, edit, delete, read, and list API versions
      * Publish to Dev Portal
      * Grant API access
  - role: "`Appearance Maintainer`"
    description: Access the Portal instance and edit its appearance.
    permissions: |
      * Read and list Dev Portals
  - role: "`Creator`"
    description: Create new Portals.
    permissions: |
      * Create, read, and list Dev Portals
  - role: "`Maintainer`"
    description: |
      Edit, view, and delete Dev Portal applications, and view developers.
      <br><br>

      {:.warning}
      > This role has the ability to approve, revoke, and delete application registrations.
    permissions: |
      * Read and list Dev Portals
      * List, read, edit, and delete applications
      * List and read developers
      * Create, edit, delete, read, and list API versions
      * Edit Dev Portal appearance
      * Publish to Dev Portal
      * Grant API access
  - role: "`Product Publisher`"
    description: Manage publishing products to a Dev Portal.
    permissions: |
      * Read and list Dev Portals
      * Create, edit, delete, read, and list API versions
      * Publish to Dev Portal
  - role: "`Viewer`"
    description: Read-only access to Dev Portal developers and applications.
    permissions: |
      * Read and list Dev Portals
      * List and read applications
      * List and read developers
      * List and read API versions
  - role: "`Content Editor`"
    description: Edits Dev Portal pages, snippets, and customization.
    permissions: |
      * Read and list Dev Portals
      * Edit pages
      * Edit snippets
      * Edit customization
  - role: "`API Registration Approver`"
    description: |
      Can approve Dev Portal application registrations.
      <br><br>

      {:.info}
      > This role also requires the Dev Portal Viewer role to view the application registrations within a Dev Portal. 
    permissions: |
      * Read and list APIs (permission is granted per API)
      * Grant API access
{% endtable %}
<!--vale on-->

#### Reports

The following table describes the predefined roles for [{{site.observability}}](/observability/) reports:

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
  - title: CRUD permissions
    key: permissions
rows:
  - role: "`Admin`"
    description: Allows users to edit and delete a Report in Konnect Analytics.
    permissions: |
      * List, read, edit, and delete reports.
  - role: "`Creator`"
    description: Allows users to create a new Report in Konnect Analytics.
    permissions: |
      * Create and list reports.
  - role: "`Editor`"
    description: Allows users to edit a Report in Konnect Analytics.
    permissions: |
      * List, edit, and read reports.
  - role: "`Viewer`"
    description: Allows users to view a Report in Konnect Analytics.
    permissions: |
      * List and read reports.
{% endtable %}
<!--vale on-->

#### API Products (Classic)

{:.warning}
> **Important:** API Product roles only apply to classic Dev Portals (v2). We recommend [migrating to the new Dev Portal (v3)](/dev-portal/v2-migration/) and using [Catalog API roles](/konnect-platform/teams-and-roles/#apis) instead. 

The following table describes the predefined roles for API Products:

<!-- vale off -->
{% konnect_roles_table %}
schema: api_products
{% endkonnect_roles_table %}
<!-- vale on -->