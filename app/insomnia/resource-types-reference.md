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
---

Resource types define the structure and identity of key entities like requests, workspaces, environments, and API design documents in  exported or synced data.

Resource types define the scope of structured data that Insomnia can interpret and operate on. By clearly identifying each entity’s role—such as a request, environment, or workspace—they enable consistent behavior across Insomnia’s interface, CLI tooling, CI pipelines, and syncing systems. This structure also helps keep workspace data clean and reliable by filtering out unsupported or obsolete metadata, ensuring only valid and meaningful entities are preserved during export, import, and collaboration.

Each object in a resources array includes a `_type field` that tells Insomnia how to interpret and process it. These resource types are used by the Insomnia application itself, by automation tools like the CLI importer/exporter. You'll encounter them when inspecting exported workspaces, syncing data across devices, or integrating Insomnia projects with Git workflows or external systems.

## Core resource types

{% table %}
    columns:
      - title: Resource type (`_type`)
        key: type
      - title: Description
        key: description
    rows:
      - type: `workspace`
        description: Top‑level container for all project data. For example, anchors requests, environments, folders, and mocks.
      - type: `environment`
        description: Scoped variable collections used to parameterize requests.
      - type: `request`
        description: Represents an individual API call, including HTTP, GraphQL, WebSocket, or gRPC operations.
      - type: `response`
        description: Sample or saved responses associated with requests, often used for documentation or testing.
      - type: `folder`
        description: Organizational grouping of other entities such as requests and environments.
      - type: `mock`
        description: Definitions of mock endpoints and behaviors for testing.
      - type: `plugin`
        description: Plugin configurations or metadata when workspace-level plugins are used.
      - type: `test`
        description: Test scripts or suites associated with requests or collections (where available).
{% endtable %}

## Logic
Resource types guide how Insomnia and its tools read, validate, and reconstruct data. The logic below explains how they're processed during import, export, and sync.
- Structured JSON includes only supported `_type` values defined in Insomnia’s schema; unsupported or deprecated types are dropped.
- Each resource object contains `_id` and `_type`; clients or CLI tools then parse these to reconstruct objects if they match supported types.
- Unsupported `_type` entries are silently ignored, avoiding potential errors or workspace corruption.
