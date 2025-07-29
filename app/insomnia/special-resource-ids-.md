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
---
Insomnia uses **special resource IDs** as placeholder identifiers to represent core workspace entities in structured JSON data. These placeholders enable accurate reconstruction of object relationships without exposing stable IDs.


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
          - placeholder: `__WORKSPACE_ID__`
            represents: Active workspace identity
            description: Abstract pointer to the workspace in JSON, rather than exposing its real ID.
          - placeholder: `__BASE_ENVIRONMENT_ID__`
            represents: Workspace’s base environment
            description: Identifies the default environment set for a workspace.
          - placeholder: `__<NAME>_<NUMBER>__`.
            represents: Random user-created entities (requests, environments)
            description: Placeholder IDs that are generated to avoid collisions and support consistent ID mapping during imports. For example: `__request_1__`, `__env_2__`.
{% endtable %}

## Behaviour and usage
When Insomnia produces structured JSON data, it replaces real UUIDs with **placeholder IDs**. These IDs serve specific internal purposes:
- **Preserve workspace structure**: Maintains logical relationships between workspaces, environments, folders, and requests.
- **Enable safe ID regeneration**: Prevents collisions by replacing fixed IDs with deterministic patterns during import.
- **Support cross-environment reuse**: Makes exported JSON portable across machines or team members without ID conflicts.
- **Obscure internal identifiers**: References entities generically to avoid exposing actual storage-layer IDs.

### How and when they're used
Insomnia uses placeholder IDs to simplify how environments, workspaces, and related data are packaged and shared. These IDs aren't static, they act as flexible references that get resolved intelligently during different stages of data handling. The following points outline where and how these identifiers come into play across Insomnia’s workflows.

- **During serialization**: Insomnia emits these IDs when generating structured JSON for syncing, CLI exports, or backups.
- **In downstream consumers**: Tools like the Insomnia importer or internal sync logic detect placeholders, automatically map them to actual or newly assigned unique IDs to recreate data structures.
- **No manual editing**: Users don’t need to modify or reconcile these IDs—each system handles resolution behind the scenes according to established logic.  
- **Collision avoidance**: When importing into an environment with existing entities, these placeholder IDs ensure no overwriting occurs.
