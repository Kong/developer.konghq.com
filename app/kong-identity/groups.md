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

description: "Learn how {{site.identity}} groups let you manage access for a set of principals in one place, and how to create groups, add members, and authenticate as a group."

related_resources:
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: "{{site.identity}} directories"
    url: /identity/directories/
---

{% include sections/principals-and-directories.md %}

## What are groups

A group is a named set of principals in a directory.
Groups let you manage access for a set of principals in one place: instead of writing one access rule per principal, or relying on every principal carrying the right metadata value, you add principals to a group and reference the group in your rules.
When a principal joins or leaves a group, you update the group's membership and the rules stay the same.

{{site.identity}} doesn't enforce access itself.
It identifies the authenticated principal and the groups it belongs to, and the gateway's access rules decide what that principal can reach.

Group membership works in the following ways:

* **Manual membership:** You add and remove each member explicitly, and a principal must already exist in the directory before you can add it to a group.
 * **Automatic mapping from an IdP:** When you enable the [Token Vault](/identity/token-vault/) on a directory, {{site.identity}} can provision principals from a trusted IdP and add them to groups based on the group names your IdP sends in its tokens. If a group doesn't exist yet, {{site.identity}} creates it. Automatic mapping only adds principals to groups of type `group`.

{{site.identity}} resolves group membership live and doesn't cache it. A membership change applies the next time the gateway authenticates the principal with {{site.identity}}.

Group names must be unique within a directory and can only contain letters and numbers, without spaces.

## Group types

You set a group's type when you create it, and you can't change it afterwards.
Groups and teams share one namespace in a directory, so a group and a team can't have the same name.

The following table compares the two types:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Group
    key: group
  - title: Team
    key: team
rows:
  - feature: "API value"
    group: "`group` (default)"
    team: "`team`"
  - feature: "Purpose"
    group: "A set of principals that you reference in access rules."
    team: "A node in your organization chart, such as a department or a team."
  - feature: "Members"
    group: "Principals of type `user` and `agent`, and principals with no type."
    team: "Principals of type `user` and other teams."
  - feature: "Nesting"
    group: "A group can't contain other groups."
    team: "A team can contain other teams."
  - feature: "Owner"
    group: "No"
    team: "A team can have an owner, which is a principal of type `user` in the same directory. The owner can't be a member of the team, and you can't delete a user who owns a team."
  - feature: "API key"
    group: "Yes"
    team: "No"
  - feature: "Basic auth, OIDC, Consumer, and auth server client credentials"
    group: "No"
    team: "No"
  - feature: "Automatic mapping from an IdP"
    group: "Yes"
    team: "No. If an IdP token names a team, {{site.identity}} skips it and doesn't add the principal."
  - feature: "Deleting with members"
    group: "Deleting a group also removes its memberships."
    team: "You can't delete a team that has members."
{% endtable %}

## Group credentials

A group of type `group` can have an API key. A request that uses that key authenticates with the group's credential, not a member's.

The key doesn't limit access to the group's members. The Key Authentication plugin looks up keys in the whole directory, so the key of any principal or group in the directory authenticates.

Create the key the same way you create a principal's API key, using the group's ID as the principal ID. 
See [Key auth](/identity/principals/#key-auth).

Teams can't have an API key. Groups and teams can't have other credentials or identities. {{site.identity}} rejects basic auth credentials, and OIDC, Consumer, and auth server client.

## Create a group and add members

Before you add members to a group, the principals must [exist in the directory](/identity/principals/#configure-a-principal).

Create the group by sending a `POST` request to the `/v2/directories/{directoryId}/groups` endpoint. 
If you omit `type`, {{site.identity}} creates a group of type `group`:

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

## Group limitations

The following are default limits for groups:

* 10,000 groups per directory
* 10,000 members per group
* 200 groups per principal
* Group names must be unique within a directory
