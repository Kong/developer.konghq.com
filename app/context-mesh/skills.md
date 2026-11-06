---
title: "{{site.context_mesh}} skills"
content_type: reference
layout: reference
beta: true

permalink: /context-mesh/skills/
description: "Reference for {{site.context_mesh}} skills, the SKILL.md files you attach to MCP servers to give agents reusable instructions, including their configuration, validation rules, and how agents read them."

products:
    - context-mesh
    - konnect

works_on:
    - konnect

breadcrumbs:
  - /context-mesh/

tags:
  - mcp
  - ai

search_aliases:
  - Skills
  - SKILL.md
  - Agent Skills

related_resources:
  - text: "{{site.context_mesh}}"
    url: /context-mesh/
  - text: "{{site.context_mesh}} MCP servers"
    url: /context-mesh/mcp-servers/
  - text: "{{site.context_mesh}} sources"
    url: /context-mesh/sources/
  - text: "{{site.context_mesh}} API reference"
    url: /api/konnect/context-interfaces/v1/
  - text: "Stages of software availability"
    url: /stages-of-software-availability/
  - text: "Agent Skills specification"
    url: https://agentskills.io/specification
  - text: "FastMCP skills provider"
    url: https://gofastmcp.com/servers/providers/skills

faqs:
  - q: Can I share a skill between {{site.context_mesh}} MCP servers?
    a: |
      No. A skill belongs to exactly one {{site.context_mesh}} MCP server. To use the same instructions on another server, create the skill again on that server.
  - q: Can I upload a zip file or add supporting files to a skill?
    a: |
      No. A skill is a single `SKILL.md` file that you submit inline. {{site.context_mesh}} doesn't support supporting files, scripts, or archive uploads.
  - q: Why don't my skills appear in the MCP server's list of tools?
    a: |
      {{site.context_mesh}} exposes skills as MCP resources, not tools. Clients discover them with `resources/list`, where each skill appears as `skill://SKILL_NAME/SKILL.md`, and read them with `resources/read`.
  - q: Are skills versioned, or can I import them from GitHub or the {{site.konnect_catalog}}?
    a: |
      No. You create skills manually by submitting the `SKILL.md` content, and there is no version history. To change a skill, update it.
  - q: Why does creating a skill fail with a `400` or `409` error?
    a: |
      A `400` error means the request is invalid. Either the `SKILL.md` frontmatter is invalid, or the request includes a `name` field. {{site.context_mesh}} takes the skill name from the `name` in the frontmatter, so don't send it separately.
      A `409` error means the MCP server already has a skill with the same name in its frontmatter. Skill names must be unique within an MCP server.
---

A skill is a single `SKILL.md` file, written in the [Agent Skills format](https://agentskills.io/specification), that you attach to a [{{site.context_mesh}} MCP server](/context-mesh/mcp-servers/). It packages task-specific instructions and reference material that an agent can pull in on demand. Unlike a tool, a skill doesn't call an API. It's read-only text served over MCP, and {{site.context_mesh}} never executes it.

For example, a Travel Assistant MCP server exposes tools like `listFlights`. A skill on that server can describe the steps an agent should follow to search, compare, and book a flight using those tools.

{:.success}
> Use a skill when an agent needs a multi-step procedure for combining the server's tools, such as the order in which to call them or what to confirm with the user.
>
> If an agent only needs to call an operation, the source's tools already cover it, and you don't need a skill.

Skills have the following properties:

* A skill belongs to exactly one {{site.context_mesh}} MCP server and can't be shared with other servers. The skill name must be unique within its MCP server.
* You submit the `SKILL.md` content inline, as the `raw` source type.
* A skill is a single file. {{site.context_mesh}} doesn't support supporting files, scripts, or archive uploads.
* Skills have no version history. To change a skill, update it.

## Skill configuration

You can configure each skill with the following fields:

{% feature_table %}
item_title: Field
columns:
  - title: Description
    key: description
  - title: Required
    key: required
features:
  - title: "Display name"
    description: Skill name in the UI.
    required: true
  - title: "Name"
    description: |
      Machine name. {{site.context_mesh}} sets it from the `name` in the `SKILL.md` frontmatter, so you don't enter it. It must be unique within the MCP server.
    required: true
  - title: "Description"
    description: A description of the skill, up to 1,024 characters.
    required: true
  - title: "Source"
    description: |
      Where the skill content comes from. Set `type` to `raw` and put the full `SKILL.md` content in `config.contents`.
    required: true
  - title: "Labels"
    description: Key-value tags for filtering/searching across {{site.konnect}}. In the API, send `{}` if you don't want to add any labels.
    required: Only with the API

{% endfeature_table %}

### SKILL.md frontmatter

The `SKILL.md` content must begin with a YAML frontmatter block. {{site.context_mesh}} validates the frontmatter when you create or update the skill, and rejects content that doesn't meet these rules:

{% table %}
columns:
  - title: Field
    key: field
  - title: Required
    key: required
  - title: Rules
    key: rules
rows:
  - field: "`name`"
    required: "Yes"
    rules: Lowercase letters, numbers, and hyphens only. Maximum 64 characters. Becomes the skill's **Name**, which must be unique within the MCP server.
  - field: "`description`"
    required: "Yes"
    rules: Non-empty. Maximum 1,024 characters.
  - field: "`license`"
    required: "No"
    rules: License name or a reference to a bundled license file.
  - field: "`compatibility`"
    required: "No"
    rules: Environment requirements for the skill. Maximum 500 characters.
  - field: "`metadata`"
    required: "No"
    rules: Key-value pairs of strings.
  - field: "`allowed-tools`"
    required: "No"
    rules: Space-separated list of pre-approved tools. The API returns this field as `allowed_tools`.

{% endtable %}

## Skill status

After validation, the skill has one of the following statuses:

{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: description
rows:
  - status: "**Valid**"
    description: The content passed validation and the skill is ready to be served.
  - status: "**Invalid**"
    description: The content failed validation. The `validation_message` field explains why.
  - status: "**Pending**"
    description: The content hasn't been read and validated yet.

{% endtable %}

## Skill changes and deployments

Creating, updating, or deleting a skill automatically triggers a new deployment of the MCP server. You don't need to restart or redeploy the server yourself. {{site.operator_product_name}} picks up the change and redeploys the MCP server on its control plane with the current set of skills.

If you haven't deployed the MCP server yet, no deployment happens. {{site.operator_product_name}} includes the skills the first time you [deploy the MCP server](/context-mesh/mcp-servers/#deploy-the-mcp-server).

## How agents use skills

{{site.context_mesh}} serves skills on the MCP server as MCP resources, and the MCP client discovers and reads them. Skills don't appear in the server's list of tools, and {{site.context_mesh}} doesn't add them to an agent's context. The client does that in the following steps:

1. The client calls `resources/list` and finds each skill as `skill://SKILL_NAME/SKILL.md`.
1. The client calls `resources/read` on a skill entry to get the raw markdown.
1. The client decides when and how to bring that content into the agent's context.

{:.warning}
> The client application is responsible for all three steps. If your MCP client doesn't support reading resources, the skills exist on the server, but your agent can't use them.

## Add a skill

Add a skill to give agents reusable instructions on the MCP server. You can add a skill before or after you deploy the server. If you've already deployed the server, adding the skill automatically triggers a new deployment. See [Skill changes and deployments](#skill-changes-and-deployments).

Write the skill in a `SKILL.md` file. The `name` in the frontmatter becomes the name of the skill, so you don't send it separately. {{site.context_mesh}} only uses the content, so the local file's name doesn't matter. The following example shows a valid skill:

```markdown
---
name: flight-booking
description: Search, compare, and book flights with the Travel Assistant tools
---

# Flight booking

Use this skill when a user asks to find or book a flight.

1. Call `listFlights` with the origin, destination, and travel date.
1. Present the three cheapest options and ask the user to pick one.
1. Confirm the passenger details before booking.
```

{:.info}
> The [{{site.context_mesh}} API](/api/konnect/context-interfaces/v1/) uses `/v1/context-interfaces` for {{site.context_mesh}} MCP servers. Wherever the endpoints refer to a context interface, that is a {{site.context_mesh}} MCP server.

{% navtabs "add-skill" %}
{% navtab "API" %}

The `contents` field takes the full contents of your skill file as a single string. Build the request body from your file with `jq`, replacing `SKILL.md` with the path to your skill file:

```sh
jq -n --rawfile contents SKILL.md '{
  "display_name": "Flight Booking",
  "description": "Search, compare, and book flights with the Travel Assistant tools",
  "labels": {},
  "source": {
    "type": "raw",
    "config": {
      "contents": $contents
    }
  }
}' > skill.json
```

This request uses the `INTERFACE_ID` environment variable, which holds the ID of your MCP server. To get it, see [Get the MCP and source IDs](/context-mesh/mcp-servers/#get-the-mcp-and-source-ids).

Send a `POST` request to the [Create a Skill](/api/konnect/context-interfaces/v1/#/operations/create-context-interface-skill) endpoint with the request body:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/skills
status_code: 201
method: POST
body_cmd: $(cat skill.json)
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **MCP Servers**.
1. Click your MCP server.
1. In **Capabilities**, click the **Skills** tab.
1. Click **Add skill**.
1. In the **Display name** field, enter a name for the skill.
1. Upload the file from your computer.
1. Click **Add skill**.

{% endnavtab %}
{% endnavtabs %}

## Manage skills

Use the following endpoints to review and change the skills on an MCP server. Updating or deleting a skill automatically triggers a new deployment.

{% table %}
columns:
  - title: Action
    key: action
  - title: Endpoint
    key: endpoint
  - title: Notes
    key: notes
rows:
  - action: "List skills"
    endpoint: "`GET` [List Skills](/api/konnect/context-interfaces/v1/#/operations/list-context-interface-skills)"
    notes: "Returns the skills attached to the MCP server."
  - action: "Get a skill"
    endpoint: "`GET` [Get a Skill](/api/konnect/context-interfaces/v1/#/operations/get-context-interface-skill)"
    notes: "The response includes the parsed `frontmatter`, the `status`, and the `validation_message` if the skill is invalid. It never includes the skill content."
  - action: "View skill content"
    endpoint: "`GET` [Get Skill Contents](/api/konnect/context-interfaces/v1/#/operations/get-context-interface-skill-contents)"
    notes: "Returns a short-lived short-lived URL for the `SKILL.md` file."
  - action: "Update a skill"
    endpoint: "`PATCH` [Update a Skill](/api/konnect/context-interfaces/v1/#/operations/patch-context-interface-skill)"
    notes: "If you send `source`, it replaces the existing source and the content is validated again. The skill name changes to the `name` in the new frontmatter, and the update fails with a `409` error if another skill on the MCP server already uses that name. You can't change the source `type`."
  - action: "Delete a skill"
    endpoint: "`DELETE` [Delete a Skill](/api/konnect/context-interfaces/v1/#/operations/delete-context-interface-skill)"
    notes: "Deletes the skill and its content."

{% endtable %}

The get, view content, update, and delete endpoints use the ID of the skill. These requests also use the `INTERFACE_ID` environment variable, which holds the ID of your MCP server. To get it, see [Get the MCP and source IDs](/context-mesh/mcp-servers/#get-the-mcp-and-source-ids).

To get the skill ID, send a `GET` request to the [List Skills](/api/konnect/context-interfaces/v1/#/operations/list-context-interface-skills) endpoint. Find your skill in the response and copy its `id`:

```sh
curl -X GET "https://us.api.konghq.com/v1/context-interfaces/$INTERFACE_ID/skills" \
     --no-progress-meter --fail-with-body \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     | jq '.data[] | {display_name, name, id}'
```

Export the ID as an environment variable, replacing `YOUR_SKILL_ID` with the `id` you copied:

```sh
export SKILL_ID='YOUR_SKILL_ID'
```

For example, to change a skill's display name without changing its content, send a `PATCH` request:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/skills/$SKILL_ID
status_code: 200
method: PATCH
body:
  display_name: Flight Booking Guide
{% endkonnect_api_request %}
<!--vale on-->
