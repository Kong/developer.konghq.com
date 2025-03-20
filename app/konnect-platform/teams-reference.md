---
title: "{{site.konnect_short_name}} Platform Teams and Roles"

description: Learn how to cancel and deactivate an account in {{site.konnect_short_name}}
content_type: reference
layout: reference


products:
  - gateway
works_on:
  - konnect

related_resources:
  - text: "{{site.konnect_short_name}} Account, Pricing, and Organization Deactivation"
    url: /konnect-platform/konnect-account/
faqs:
  - q: Where can you find a list of all teams in your organization in {{site.konnect_short_name}}?
    a: You can find a list of all teams under **Organization** > **Teams** in {{site.konnect_short_name}}.
  - q: What is required to manage users, teams, and roles in {{site.konnect_short_name}}?
    a: You must be part of the **Organization Admin team** to manage users, teams, and roles.
  - q: What is a team in {{site.konnect_short_name}}?
    a: A team is a group of users with access to the same roles. Teams allow assigning access to {{site.konnect_short_name}} resources based on roles.
  - q: What is a role in {{site.konnect_short_name}}?
    a: |
      A role defines predefined access to a particular resource or instances of a resource type. For example, API product roles can be scoped to a specific API product or all API products, while control plane roles can be scoped to a specific control plane or all control planes.
  - q: Can predefined teams in {{site.konnect_short_name}} be modified or deleted?
    a: No, predefined teams have fixed role sets that cannot be modified or deleted.

---


## Teams and roles

You can find a list of all teams in your organization through **Organization** > **Teams** in {{site.konnect_short_name}}.

You must be part of the Organization Admin team to manage users, teams, and
roles.

* **Team:** A group of users with access to the same roles. Teams are useful
for assigning access by functionality, they can provide granular access to
any group of {{site.konnect_short_name}} resources based on roles.

* **Role:** Predefined access to a particular resource, or
instances of a particular resource type (for example, API product roles can be scoped to a particular API product or all API products whilst control plane roles can be scoped to a particular control plane or all control planes).

## Predefined teams

All new and existing organizations in {{site.konnect_short_name}} have predefined default teams. The default teams can't be modified or deleted.

| Team                           | Description  |
|--------------------------------|--------------|
| Analytics Admin                | Users can fully manage all Analytics content, which includes creating, editing, and deleting reports, as well as viewing the analytics summary. |
| Analytics Viewer               | Users can view the Analytics summary and report data.|
| Organization Admin             | Users can fully manage all entities and configuration in the organization. |
| Organization Admin (Read Only) | Users can view all entities and configuration in the organization. |
| Portal Admin                   | Users can fully manage all Dev Portal content, which includes {{site.konnect_short_name}} service pages and supporting content, as well as Dev Portal configuration and Service connections. <br> To manage app registration requests, members must also be assigned to the Admin or Maintainer roles for the corresponding Services.|
| API Product Admin              | Users can create and manage API products, including publishing API product versions to Dev Portal and enabling application registration.|  
| API Product Developer          | Users can create and manage versions of API products. |
| Control Plane Admin            | Users can create and manage control planes. | 


### Access precedence

Users can be part of any number of teams, and the roles gained from the teams
are additive. For example, if you add a user to both the Service Developer and
`Portal Viewer` teams, the user can create and manage Services
through API Products _and_ register applications through the Dev Portal.

If two roles provide access to the same entity, the role with more access
takes effect. For example, if you have the Service Admin and Service Deployer
roles on the same Service, the Service Admin role takes precedence.

### Geographic region assignment

Teams and roles can be assigned to a specific [geographic regions](/{site.konnect_short_name}}-geos/) in {{site.konnect_short_name}}. Those teams and roles only access {{site.konnect_short_name}} objects, such as Services, that are also located in the same geo they are assigned to.
