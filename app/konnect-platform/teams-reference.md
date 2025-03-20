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

Many organizations have strict security requirements. For example, organizations
need the ability to segregate the duties of an administrator to ensure that a
mistake or malicious act by one administrator doesn’t cause an outage.

To help secure and govern your environment, {{site.konnect_short_name}} provides
the ability to manage authorization with teams and roles. You can use {{site.konnect_short_name}}'s
predefined teams for a standard set of roles, or create custom teams with
any roles you choose. Invite users and add them to these teams to manage user
access.

## Teams and roles

{{site.konnect_short_name}} defines teams and roles as the following:
* **Team:** A group of users with access to the same roles. Teams are useful
for assigning access by functionality, they can provide granular access to
any group of {{site.konnect_short_name}} resources based on roles.
* **Role:** Predefined access to a particular resource, or
instances of a particular resource type (for example, API product roles can be scoped to a particular API product or all API products while Control Plane roles can be scoped to a particular Control Plane or all Control Planes).

You can find a list of all teams in your organization through **Organization** > **Teams** in {{site.konnect_short_name}}.

You must be part of the Organization Admin team to manage users, teams, and
roles.

## Predefined teams

All new and existing organizations in {{site.konnect_short_name}} have predefined default teams. The default teams can't be modified or deleted.

| Team                           | Description  |
|--------------------------------|--------------|
| Analytics Admin                | Users can fully manage all [Analytics](/advanced-analytics/) content, which includes creating, editing, and deleting reports, as well as viewing the analytics summary. |
| Analytics Viewer               | Users can view the [Analytics](/advanced-analytics/)  summary and report data.|
| Organization Admin             | Users can fully manage all entities and configuration in the organization. |
| Organization Admin (Read Only) | Users can view all entities and configuration in the organization. |
| Portal Admin                   | Users can fully manage all Dev Portal content, which includes {{site.konnect_short_name}} service pages and supporting content, as well as Dev Portal configuration and Service connections. <br> To manage app registration requests, members must also be assigned to the Admin or Maintainer roles for the corresponding Services.|
| API Product Admin              | Users can create and manage API products, including publishing API product versions to Dev Portal and enabling application registration.|  
| API Product Developer          | Users can create and manage versions of API products. |
| Control Plane Admin            | Users can create and manage Control Planes. | 


### Access precedence

Users can be part of any number of teams, and the roles gained from the teams
are additive. For example, if you add a user to both the Service Developer and
Portal Viewer teams, the user can create and manage Services
through API Products _and_ register applications through the Dev Portal.

If two roles provide access to the same entity, the role with more access
takes effect. For example, if you have the Service Admin and Service Deployer
roles on the same Service, the Service Admin role takes precedence.

### Geographic region assignment

Teams and roles can be assigned to a specific [geographic regions](/konnect-geos/) in {{site.konnect_short_name}}. Those teams and roles can only access {{site.konnect_short_name}} objects, such as Services, that are also located in the same geo they are assigned to.
