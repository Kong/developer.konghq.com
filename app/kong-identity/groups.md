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

A group is a named list of principals in a directory, that allows you to share a secret with a list of [principals](/identity/principals/). Instead of writing a rule for each principal to gain access to a secret, you write a rule once and apply it to a group. The rule affects all members of the group.

Groups save time and ease secret sharing. You add people to the group once, and from then on you manage them together instead of one by one.

Use a group when you want to apply these actions to a set of principals:

* Sharing a [Token Vault](/identity/token-vault/) secret. 
* Set spend limits.

{{site.identity}} identifies the authenticated principal and the groups it belongs to, and passes both to the gateway.

## Adding members to a group

Group membership works in the following ways:

* **Manual membership:** You add and remove each member explicitly, and a principal must already exist in the directory before you can add it to a group.
* **Automatic mapping from an IdP:** When you enable the [Token Vault](/identity/token-vault/) on a directory, {{site.identity}} can provision principals from a trusted IdP and add them to groups based on the group names your IdP sends in its tokens. If a group doesn't exist yet, {{site.identity}} creates it. Automatic mapping only adds principals to groups of type `group`.

{{site.identity}} resolves group membership live and doesn't cache it. A membership change applies the next time the gateway authenticates the principal with {{site.identity}}.

Group names must be unique within a directory and can only contain letters and numbers, without spaces.

## Groups and teams

Groups and teams both hold principals, but they answer different questions:

* **A group answers "who shares this?"** Use it to manage a set of principals together, give them a shared spend limit, or give them a shared key. A group is a flat list that can't contain other groups.
* **A team answers "where does this person sit in the organization?"** A team is a node in your organization structure, such as a department. Teams can contain other teams, each team has an owner, and only users can be members. Teams can carry spend limits too. A child team's limit can't exceed its parent's, and a user gets the lowest limit from their team and its parent teams.

You create teams by importing a file, not by hand. To change a team, update your source and import again. Users created by an import are read-only until the next import.

Teams don't hold keys. To give the people in a team something shared, such as a key or a spend limit, add them to a group.

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
    group: "A set of principals that share a spend limit or a key."
    team: "A node in your organization structure, such as a department."
  - feature: "Members"
    group: "Principals."
    team: "Principals of type `user` and other teams."
  - feature: "Nesting"
    group: "A group can't contain other groups."
    team: "A team can contain other teams."
  - feature: "Owner"
    group: "No owner"
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

## Group API keys

A group API key is a shared credential that belongs to the group, not to a single principal. It carries the group's permissions and budget's limitations. A request made with it authenticates as the group, and anything it spends counts against the group's spend limit. 

Use a group key when the tool making requests doesn't belong to one person, for example a shared script or tool that a set of principals uses. 
The group's spend limit then caps what that shared client can spend.

Keep the following in mind:

* The request authenticates as the group. It doesn't carry the identity of a member.
* Only groups of type `group` can have an API key. Groups of type `team` can't.
* Groups can't have any other credential or identity. {{site.identity}} rejects basic auth credentials and OIDC, Consumer, and auth server client identities for a group.

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

## Add an API key to a group

To create a key for a group, send a `POST` request to the `/v2/directories/{directoryId}/groups/{groupId}/api-keys` endpoint. 
The key can be system-generated (`v1`) or imported with a custom secret (`imported`). The secret is only returned when the key is created. 
For details about key types, see [Key auth](/identity/principals/#key-auth).

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups/$GROUP_ID/api-keys
status_code: 201
method: POST
body:
  type: v1
{% endkonnect_api_request %}
<!--vale on-->

To list, update, or delete a group's keys, use the same endpoint with `GET`, `PATCH`, or `DELETE`, adding the key ID to the path for a single key.

## Group limitations

The following are default limits for groups:

* 10,000 groups per directory
* 10,000 members per group
* 200 groups per principal
* Group names must be unique within a directory
