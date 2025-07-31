---
title: Special resource IDs
content_type: reference

layout: reference

products:
  - insomnia

description: High‑level overview of special resource IDs used internally by Insomnia to map workspace structure and entities.

tags:
  - import-export
  - technical-reference
  - identifiers
  - serialization

related_resources:
  - text: Import an API specification as a design document in Insomnia
    url: /how-to/import-an-api-spec-as-a-document/
  - text: Export an API specification as a design document in Insomnia
    url: /how-to/export-an-api-spec-as-a-document/
  - text: Resource types reference
    url: /insomnia/resource-types-reference/     
---
Insomnia uses **special resource IDs** as placeholder identifiers to represent core workspace entities in structured JSON data during export and sync operations. These placeholders help maintain the workspace structure and allow seamless data reconstruction when importing or syncing JSON files across systems or team environments.

## Types of special resource IDs
Use the following table to learn about our special resource IDs:
{% table %}
columns:
  - title: Placeholder format
    key: placeholder
  - title: Represents
    key: represents
  - title: Description
    key: description
rows:
  - placeholder: "`__WORKSPACE_ID__`"
    represents: Active workspace identity
    description: Abstract pointer to the workspace in JSON, rather than exposing its real ID.
  - placeholder: "`__BASE_ENVIRONMENT_ID__`"
    represents: Workspace’s base environment
    description: Identifies the default environment set for a workspace.
  - placeholder: "`__<NAME>_<NUMBER>__`"
    represents: Random user-created entities (requests, environments)
    description: "Placeholder IDs that are generated to avoid collisions and support consistent ID mapping during imports. For example: `__request_1__`, `__env_2__`"
{% endtable %}

## Purpose of special resource IDs
When Insomnia produces structured JSON data, it replaces real UUIDs with **placeholder IDs**. These IDs serve specific internal purposes:
- **Preserve workspace structure**: Maintains logical relationships between workspaces, environments, folders, and requests.
- **Enable safe ID regeneration**: Prevents collisions by replacing fixed IDs with deterministic patterns during import.
- **Support cross-environment reuse**: Makes exported JSON portable across machines or team members without ID conflicts.
- **Obscure internal identifiers**: References entities generically to avoid exposing actual storage-layer IDs.

## When special resource IDs apply
Insomnia handles special resource IDs in different stages of your workflow:
- **During serialization**: Insomnia exports workspace data—for syncing, CLI exports, or backups—it replaces real UUIDs with placeholder IDs such as `__WORKSPACE_ID__`, `__BASE_ENVIRONMENT_ID__`, or `__<NAME>_<NUMBER>__`. These placeholders mark key entities for later resolution.
- **In downstream consumers**: Importers and built-in sync logic detect these placeholders during import or sync and map them to actual or newly generated unique IDs. This process preserves object relationships and workspace structure.
- **Without manual intervention**: You don't need to edit or reconcile these IDs manually. Insomnia automatically resolves them at import without user involvement.
- **To avoid collisions**: When you import data into an environment with existing entities, Insomnia uses placeholder IDs to generate new unique IDs and prevent ID conflicts or accidental overwrites.
