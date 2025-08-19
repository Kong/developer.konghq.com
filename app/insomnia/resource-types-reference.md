---
title: Resource Types

content_type: reference

layout: reference

products:
  - insomnia

description: High‑level overview of the supported resource types that Insomnia uses internally from the `resources` array in its structured JSON.

tags:
  - import-export
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
Resource types specify what each object in the resources array represents in workspace data that you exported and synced. Each object contains a `_type` field that Insomnia uses to interpret and reconstruct the data.

Supported resource types ensure that only valid entities appear in exports, unsupported, or deprecated types are omitted. 
 
You encounter resource types whenever you export data, sync across devices, or integrate Insomnia exports with Git or automation workflows. 

## Supported resource types

Insomnia defines a set of core resource types that the system recognizes when exporting or syncing workspace data. Each object in the resources array features a `_type` value that tells Insomnia what kind of entity it represents. 

Use the following table to view the list of core types and descriptions of their role in workspace structure and import logic:

{% table %}
columns:
  - title: Resource type (`_type`)
    key: type
  - title: Description
    key: description
rows:
  - type: "`workspace`"
    description: The top‑level container for all project data, that groups requests, environments, folders, and mocks.
  - type: "`environment`"
    description: A set of variables used to parameterize requests, including base or nested environments.
  - type: "`request`"
    description: An individual API call that may use HTTP GraphQL WebSocket or gRPC protocols.
  - type: "`response`"
    description: A sample or a saved response that is tied to a request.
  - type: "`folder`"
    description: A logical grouping of related entities, for example requests and environments.
  - type: "`mock`"
    description: A local mock endpoint definitions and behaviors for testing.
  - type: "`plugin`"
    description: A workspace-level plugin configuration or metadata.
  - type: "`test`"
    description: A script or test suite associated with requests or collections.
{% endtable %}