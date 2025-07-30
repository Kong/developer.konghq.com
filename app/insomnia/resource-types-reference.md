---
title: Resource Types

content_type: reference

layout: reference

products:
  - insomnia

description: High‑level overview of the supported resource types that Insomnia uses internally from the `resources` array in its structured JSON.

tags:
  - import-export
  - technical-reference
  - schema
  - serialization

related_resources:
  - text: Import an API specification as a design document in Insomnia
    url: /how-to/import-an-api-spec-as-a-document/
  - text: Export your API design document or request data
    url: /how-to/export-an-api-spec-as-a-document/
  - text: Special resource IDs
    url: /insomnia/special-resource-ids/   
---

Resource types define the structure and role of key entities in exported or synced Insomnia data, for example requests, workspaces, environments, and API design documents. 

Each object in the resources array includes a `_type` field that tells Insomnia how to interpret and process it. These types ensure consistent behavior across the Insomnia app, CLI tools, CI pipelines, and sync systems. By clearly identifying supported entities, resource types help maintain clean, reliable workspace data and exclude obsolete or unsupported metadata. 

You’ll encounter them during export and import operations, across device syncs, and when you integrate Insomnia projects with Git or automation workflows.

## Core resource types

{% table %}
columns:
  - title: Resource type (`_type`)
    key: type
  - title: Description
    key: description
rows:
  - type: "`workspace`"
    description: Top‑level container for all project data. For example, anchors requests, environments, folders, and mocks.
  - type: "`environment`"
    description: Scoped variable collections used to parameterize requests.
  - type: "`request`"
    description: Represents an individual API call, including HTTP, GraphQL, WebSocket, or gRPC operations.
  - type: "`response`"
    description: Sample or saved responses associated with requests, often used for documentation or testing.
  - type: "`folder`"
    description: Organizational grouping of other entities such as requests and environments.
  - type: "`mock`"
    description: Definitions of mock endpoints and behaviors for testing.
  - type: "`plugin`"
    description: Plugin configurations or metadata when workspace-level plugins are used.
  - type: "`test`"
    description: Test scripts or suites associated with requests or collections (where available).
{% endtable %}

## Logic
Resource types guide how Insomnia and its tools read, validate, and reconstruct data. The logic below explains how they're processed during import, export, and sync.
- Structured JSON includes only supported `_type` values defined in Insomnia’s schema; unsupported or deprecated types are dropped.
- Each resource object contains `_id` and `_type`; clients or CLI tools then parse these to reconstruct objects if they match supported types.
- Unsupported `_type` entries are silently ignored, avoiding potential errors or workspace corruption.
