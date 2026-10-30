---
name: author-event-gateway-guide
description: Author a new Event Gateway how-to guide. Use when the user wants to create a new guide for Kong Event Gateway, including step-by-step instructions with API calls, kafkactl commands, and validation steps.
argument-hint: <topic-description>
---

## Author an Event Gateway How-To Guide

Create a new how-to guide for Kong Event Gateway based on the user's topic description: `$ARGUMENTS`

### Phase 1: Build Context

Read the following files to understand conventions, formats, and existing patterns:

1. **Existing guides** in `app/_how-tos/event-gateway/` — read ALL of them to understand frontmatter structure, formatting conventions, and the `{% konnect_api_request %}` / `{% validation custom-command %}` patterns.
2. **Policy files** in `app/_event_gateway_policies/` — read the policies relevant to the guide topic.
3. **Entity references** in `app/event-gateway/entities/` — read entities relevant to the guide.
4. **Shared includes** in `app/_includes/knep/` — understand reusable components like `create-backend-cluster.md`, `docker-compose-start.md`, `kafkactl.md`.
5. **Docker compose** at `app/_includes/_files/event-gateway/docker-compose.yaml` — the base infrastructure.
6. **API specification** at `https://developer.konghq.com/api/konnect/event-gateway/v1/` - the entire openAPI spec, do not read in one call as it's too large for your context.

After reading, present a summary of what you understand and **ask the user if anything is missing** before proceeding.

### Phase 2: Plan the Scenario

Present a detailed plan covering:

1. **Scenario**: What real-world use case the guide demonstrates, with concrete examples.
2. **Data model**: What events/messages will be used (prefer reusing patterns from existing guides for coherency).
3. **Flow**: Step-by-step outline of what the guide will cover.
4. **Infrastructure changes**: Whether docker-compose or shared includes need modification.

Wait for user approval before proceeding.

### Phase 3: Plan the Implementation

Present a second plan with:

1. **Files to create**: New guide file path and name.
2. **Files to modify**: Any changes to docker-compose, shared includes, or policy docs to link to the new guide.
3. **Exact section order** of the guide.

Wait for user approval before proceeding.

### Phase 4: Write the First Draft

Write the guide following these conventions learned from existing guides:

#### Frontmatter Structure
```yaml
---
title: Guide Title
content_type: how_to
breadcrumbs:
  - /event-gateway/
permalink: /event-gateway/guide-slug/
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway
    - kafka
description: "Short description."
tldr:
  q: How can I...?
  a: |
    1. Step one.
    1. Step two.
tools:
    - konnect-api
prereqs:
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start
cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg
related_resources:
  - text: Resource name
    url: /event-gateway/path/
---
```

#### Section Ordering
The guide should generally follow this order:
1. **Overview** with a mermaid diagram showing the data flow.
2. **Event Gateway setup** (backend cluster, virtual cluster, listener, policies) — set up the infrastructure first.
3. **Configure kafkactl** — define all needed contexts in a single config file. Include both `direct` (for direct Kafka access) and `vc` (for virtual cluster access) contexts if needed.
4. **Kafka setup** (create topics, register schemas, etc.) — use the kafkactl config from the previous step.
5. **Validate** — when possible demonstrate the feature working (positive case) and failing (negative case).

#### API Calls
Use `{% konnect_api_request %}` blocks for Event Gateway API calls:
```
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/...
status_code: 201
method: POST
body:
  ...
extract_body:
  - name: id
    variable: VARIABLE_NAME
capture: VARIABLE_NAME
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->
```

#### Shell Commands
Use `{% validation custom-command %}` blocks for shell commands:
```
<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C config.yaml --context ctx ...
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->
```

#### Important
- If the information available to use a feature is too sparse do not hesitate to ask user to link the design docs and implementation pull requests.
- Keep the guide as brief as possible
- Use as little features as possible to showcase the demo (.e.g: don't add authentication if we don't need)
- If the user wants to start demonstrating too many things, gently push back suggesting creating multiple guides


#### Reusable Includes
- Backend cluster creation: `{% include knep/create-backend-cluster.md %}` (add `insecure=true` if using anonymous virtual cluster auth)
- Always use `{{site.event_gateway}}` / `{{site.event_gateway_short}}` / `{{site.konnect_short_name}}` site variables, never hardcode product names.

#### kafkactl Conventions
- Always specify `-C <config-file> --context <context>` in every kafkactl command.
- Define all contexts in a single yaml config file created in the guide.
- Use the `vc` context name for virtual cluster connections.

#### Output Examples
Show expected output in fenced code blocks with `{:.no-copy-code}`:
```
```shell
expected output here
```
{:.no-copy-code}
```

### Phase 5: Pause for Review

After writing the first draft, **stop and ask the user to review**. Present a summary of what was written and what files were changed. Iterate based on feedback before considering the guide complete.

### Phase 6: Update Related Docs

After the guide is approved, update related policy docs or entity pages to link to the new guide (e.g., adding an entry to the use cases table in `app/_includes/knep/schema-validation.md`).
