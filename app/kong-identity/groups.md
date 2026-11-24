---
title: "Groups"
content_type: reference
layout: reference
permalink: /identity/groups/
products:
  - identity
  - konnect
api_specs:
    - konnect/kong-identity-principals
works_on:
  - konnect

breadcrumbs:
  - /identity/

min_version:
  gateway: '3.15'

description: "Named sets of principals in a directory. Use a group to apply one access rule, spend limit, or shared key to many principals."

faqs:
  - q: Can I create a team and add users to it manually?
    a: |
       No. You can only create a team from the [org structure file](/ai-cost-management/org-chart/) you import.
      {{site.konnect_short_name}} creates teams from the reporting lines in the file, and teams and their members change only when you upload a new file.


related_resources:
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: "{{site.identity}} directories"
    url: /identity/directories/
  - text: "Token Vault"
    url: /identity/token-vault/
  - text: "Token Vault credentials"
    url: /identity/token-vault/credentials/
  - text: "Get started with the {{site.identity}} Token Vault"
    url: /how-to/get-started-with-token-vault/
  - text: "Authenticate Principals with the Key Authentication plugin"
    url: /how-to/authenticate-principals-with-key-auth/
---

{% include sections/principals-and-directories.md %}

## What are groups?

A group is a named list of [principals](/identity/principals/) in a directory that allows you to share a resource with all of them. Instead of writing a rule for each principal, you write a rule once and apply it to a group. The rule affects all members of the group.


Use a group when you want to apply these actions to a set of principals:

* Sharing a [Token Vault](/identity/token-vault/) secret, such as a [shared API key](/identity/token-vault/credentials/#static-secret).
* Setting spend limits.
* Sharing an API key.
* Applying ACLs.

{{site.identity}} identifies the authenticated principal and the groups it belongs to, and passes both to the gateway.

## Adding members to a group

Group membership works in the following ways:

* **Manual membership:** You add and remove each member explicitly, and a principal must already exist in the directory before you can add it to a group.
* **Automatic mapping from an IdP:** When you enable the [Token Vault](/identity/token-vault/) on a directory, {{site.identity}} can provision principals from a trusted IdP and add them to groups based on the group names your IdP sends in its tokens. If a group doesn't exist, {{site.identity}} creates it. Automatic mapping only adds principals to groups of type `group`.

{{site.identity}} doesn't cache group membership. When membership changes, the new groups apply the next time the gateway authenticates the principal.

Group names must be unique within a directory and can only contain letters, numbers, and hyphens, without spaces.

## Group types

{{site.identity}} allows the following types of groups:

* A default group, containing principals of any type.
* A [project](#projects): a group that lets a set of users and agents work together on a specific effort.
* A [team](#group-features): a type of group defined in an org chart file you import.

Groups, teams, and projects all contain principals, but each serves a different purpose:
* **Group**: Shares resources across a set of principals. Use a group to manage principals together, or to give them a shared spend limit or key.
* **Team**: Represents where a user sits in your organization, such as a department. It models your org structure and allows you to set spend limits that apply down the hierarchy.
* **Project**: Represents a specific effort. Use a project to give a set of users and agents shared access to that work.

You set a group's type when you create it, and you can't change it afterwards.
The `team` type is set automatically during org chart import.

A group, team, and project in the same directory can't have the same name.

See the following table for a comparison of the group types:

You set a group's type when you create it, and you can't change it afterwards.
A group, team, and project in the same directory can't have the same name.

The following table compares the types:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Group
    key: group
  - title: Team
    key: team
  - title: Project
    key: project
rows:
  - feature: "Purpose"
    group: "A set of principals that share a spend limit or a key."
    team: "A node in your organization structure, such as a department."
    project: "A set of users and agents that work together on a specific effort, such as a hackathon."
  - feature: "Members"
    group: "Principals."
    team: "Principals of type `user` and other teams."
    project: "Principals of type `user` and `agent`."
  - feature: "Nesting"
    group: "A group can't contain other groups."
    team: "A team can contain other teams."
    project: "A project can't contain groups, teams, or other projects, and can't be a member of a group or team."
  - feature: "Owner"
    group: "No owner"
    team: "A team can have an owner, which is a principal of type `user` in the same directory. The owner can't be a member of the team, and you can't delete a user who owns a team."
    project: "No owner"
  - feature: "API key"
    group: "Yes"
    team: "No"
    project: "Yes"
  - feature: "Automatic mapping from an IdP"
    group: "Yes"
    team: "No. {{site.identity}} ignores a team name in an IdP token and doesn't add the principal to the team."
    project: "No. {{site.identity}} ignores a project name in an IdP token and doesn't add the principal to the project."
  - feature: "Deleting with members"
    group: "Deleting a group also removes its memberships."
    team: "You can't delete a team that has members."
    project: "Deleting a project also removes its memberships."
{% endtable %}

## Projects

A project is a type of group that represents a temporary or special-purpose effort, such as a hackathon. It holds a set of users and agents that work together on that effort.

A project is a membership list. It doesn't grant access by itself: ACLs control access, and they target models and MCP servers. Projects don't support inheritance, and an administrator must add each member explicitly.

To create a project, set `type` to `project` when you [create a group](#create-a-group-and-add-members). Then add members in the same way as for any group.

## Group API keys

A group API key is a shared credential that belongs to the group, not to a single principal. It carries the group's permissions and spend limit. A request made with it authenticates as the group, and anything it spends counts against the group's spend limit.

Use a group key when the tool making requests doesn't belong to one person, for example a shared script or tool that a set of principals uses.

Keep the following in mind:

* The request doesn't carry the identity of a member.
* Only groups of type `group` and `project` can have an API key. Groups of type `team` can't.

## Create a group and add members

Before you add members to a group, the principals must [exist in the directory](/identity/principals/#configure-a-principal).

{% navtabs "create-group" %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **Access Management**.
1. In the Access Management sidebar, click [**Groups**](https://cloud.konghq.com/identity/access-management/groups).
1. Click **New Group**.
1. From the **Type** dropdown menu, select "Group".
1. In the **Name** field, enter `PlatformEngineers`.
1. In the **Description** field, enter `Members of the platform engineering team`.
1. From the **Users and agents** dropdown menu, select the users and agents to add to the group.
1. Click **New Group**.

To create a project:

1. In the Access Management sidebar, click [**Groups**](https://cloud.konghq.com/identity/access-management/groups).
1. In the **Projects** section, click **New Project**.
1. In the **Name** field, enter `Hackathon2026`.
1. In the **Description** field, enter `Members of the autumn hackathon`.
1. From the **Users and agents** dropdown menu, select the users and agents to add to the project.
1. Click **New Project**.

To add members to an existing group or project:

1. In the Access Management sidebar, click [**Groups**](https://cloud.konghq.com/identity/access-management/groups).
1. Click **PlatformEngineers**.
1. Click **Add members**.
1. From the **Users and agents** dropdown menu, select the users and agents to add.
1. Click **Add**.

{% endnavtab %}
{% navtab "API" %}

Create the group by sending a `POST` request to the `/v2/directories/{directoryId}/groups` endpoint. 
If you omit `type`, {{site.identity}} creates a group of type `group`. To create a project, set `type` to `project`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups
status_code: 201
method: POST
body:
  name: PlatformEngineers
  description: Members of the platform engineering team
  type: group
{% endkonnect_api_request %}
<!--vale on-->

Then, add a principal to the group by sending a `POST` request to the `/v2/directories/{directoryId}/groups/{groupId}/membership` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups/$GROUP_ID/membership
status_code: 201
method: POST
body:
  member:
    id: $PRINCIPAL_ID
    type: principal
{% endkonnect_api_request %}
<!--vale on-->

The response contains a membership entry ID. 
To remove the principal from the group, send a `DELETE` request to the `/v2/directories/{directoryId}/groups/{groupId}/membership/{groupMembershipId}` endpoint with that ID.
To list the members of a group, send a `GET` request to the `/v2/directories/{directoryId}/groups/{groupId}/membership` endpoint.

{% endnavtab %}
{% endnavtabs %}

## Group limitations

The following are default limits for groups:

* 10,000 groups per directory, including teams and projects
* 10,000 members per group
* 200 groups per principal
