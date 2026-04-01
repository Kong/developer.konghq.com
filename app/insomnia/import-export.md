---
title: Import and export reference for Insomnia
content_type: reference
layout: reference
breadcrumbs:
  - /insomnia/

products:
  - insomnia

search_aliases:
  - import
  - export
  - inso

description: Learn how to import and export data in Insomnia using the UI and the Inso CLI, and which formats are supported.
faqs:
  - q: What are special resource IDs in Insomnia exports?
    a: |
      Special resource IDs are placeholder values used during a workspace export. 
      When Insomnia serializes data, it replaces actual UUIDs with these placeholders to mark important entities for later resolution.
      During import or sync, these placeholders are automatically mapped to real or newly generated IDs to preserve object relationships and workspace structure.

  - q: Why aren’t all environment variables visible in the table view?
    a: |
      Nested environment variables may not appear in the table view. 
      If this happens, switch to the **JSON** view to see the full environment variable structure.

  - q: Why is my exported file missing the `.json` extension?
    a: |
      In some environments—especially Linux with Flatpak—exported files may be missing the `.json` extension. 
      If this happens, you can manually add the extension.

  - q: What’s the difference between "Export all data" and scoped export options?
    a: |
      * **Export all data**: Includes your entire account's data.
      * **Scoped export options**: Allow you to export only specific parts of your data, such as a single **Document** or **Project**, for more targeted backups or sharing.

related_resources:
  - text: Inso CLI reference
    url: /inso-cli/cli-command-reference/
  - text: Design documents
    url: /insomnia/get-started-with-documents/
  - text: Insomnia Storage Options
    url: /insomnia/insomnia-storage-options-guide/
  - text: Get started with documents
    url: /insomnia/get-started-with-documents/
  - text: Storage options in Insomnia
    url: /insomnia/insomnia-storage-options-guide/
  - text: Import content from Postman to multiple Insomnia projects
    url: /how-to/import-content-from-postman-to-multiple-insomnia-projects/
  - text: Migrate collections and environments from Postman to Insomnia
    url: /how-to/migrate-collections-and-environments-from-postman-to-insomnia/
---

Insomnia offers a unified workflow for importing and exporting API artifacts. Whether you're using the desktop UI or automating tasks through the Inso CLI, this page outlines the methods, their compatibility, and the practical use cases to fit a variety of developer workflows.

## Typical use cases

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Method
    key: method
rows:
  - use_case: Export a design document for version control
    method: |
      UI export from document menu or Preferences; or `inso export spec` for OpenAPI in CI.
  - use_case: Transfer all API work to another machine
    method: |
      **UI → Preferences → Data → Export** all data.
  - use_case: Import a Postman collection or OpenAPI spec into Insomnia
    method: |
      **UI → Import → choose File/Clipboard/URL**.
  - use_case: Integrate spec validation into CI pipelines
    method: |
      In CI, use `inso lint spec <identifier>` to lint OpenAPI and fail builds on errors.
  - use_case: Automate test execution from Insomnia test suites in CI
    method: |
      In CI, use `inso run test <identifier>` to run defined tests and return pass/fail exit codes.
  - use_case: Import a Postman environment into Insomnia
    method: | 
      1. Organize each project into its own folder.
      1. Use **Import > From Folder** from within the Insomnia UI.
{% endtable %}
<!-- vale on -->

During imports and exports, Insomnia serializes workspace data by replacing real UUIDs with special resource IDs and classifying each item by resource type:
- **Resource Type**: An object that specifies the type of information in the request. Insomnia includes only supported entities in exports; indicated by the `_type` field in each resource object. Deprecated or unsupported types are excluded. 
- **Special Resource ID**: A placeholder identifier that Insomnia uses to preserve workspace structure, prevent identifier collisions, enable cross-environment reuse, and obscure storage-layer IDs. Insomnia replaces real UUIDs with placeholders like `__WORKSPACE_ID__`, `__BASE_ENVIRONMENT_ID__`, or `__<NAME>_<NUMBER>__`. These placeholders are resolved on import.

## Import methods

Depending on your workflow requirements, you can import into Insomnia with either of the following methods:
- UI import
- CLI import

### UI import


In a workspace or document header, select **Import** and then specify your import method:
- File
- URL
- Clipboard

Insomnia supports the following formats:
- **Import formats**: Insomnia JSON, Postman v2.0/v2.1, HAR, OpenAPI 3.0/3.1, Swagger, WSDL, and cURL
- **Export formats (UI)**: Insomnia JSON (v4/v5) and  HAR
- **Export formats (CLI)**: OpenAPI spec

For more information on importing with the UI, go to [how to import an API spec as a document](/how-to/import-an-api-spec-as-a-document/).

### CLI import
Use Inso CLI to supplement UI workflows with command-line capabilities. Instead of importing files into the application directly, you can use Inso CLI to run tests, execute collections, validate specs, export OpenAPI artifacts, and run custom scripts.

An example of our key commands:
* **Execute test suites via CLI**

  `inso run test "<Design Document Name>" --env "<Environment Name>"`: Runs unit tests defined in the Insomnia application. The execution runs as in CI pipelines and returns a non-zero exit code if tests fail.
* **Validate an OpenAPI specification**

  `inso export spec "<Design Document Name>" --output <filename>.yaml`: Extracts the raw OpenAPI spec tied to a design document. Without `--output`, the CLI prints the spec to stdout for easy scripting.

* **Run request collections automatically**

  `inso run collection "<Collection Name>" --env "<Environment Name>"`: Runs all requests and scripts in a collection as a batch. This is ideal for automation and guarantees consistency across environments.

For more information, see the [Inso CLI reference](/inso-cli/).

## Export methods

Insomnia supports flexible export options that are tailored to both manual and automated workflows. You can either use the desktop app, ideal for immediate data transfer or archival, or use Inso CLI to script OpenAPI specification exports within CI pipelines.

### UI export
In a workspace or document header, select **Export**  and then specify the file type. The following file types are supported:
- **Document**: Export only the active design document. This includes the requests, environment settings, and tests. It does not include other workspace data.
- **Project**: Export the selected collection. This includes all contained requests and environments.
- **All data**: Export everything in your workspace.

The UI method supports the following formats:
- Insomnia JSON (v4/v5)
- HAR

### CLI export
Use Inso CLI to automate exports of your OpenAPI specification from a design document. You can write the spec to a file, or let the CLI print to standard output for piping in scripts and CI. For a full overview, see the Inso CLI reference.

An example of the key commands:
* **Export an OpenAPI spec to a file**
  
  Use `inso export spec "<Design Document Name>" --output spec.yaml` to extract the raw OpenAPI specification tied to a design document and save it to a file. The identifier can be the spec name or its ID.

* **Export to standard output for piping**
  
  Use `inso export spec "<Design Document Name>"` without `--output` to print the spec to the console. This is useful for shell redirection or piping into other tools. 

## Resource types

Resource types specify what each object in the resources array represents in workspace data that you exported and synced. Each object contains a `_type` field that Insomnia uses to interpret and reconstruct the data.

Supported resource types ensure that only valid entities appear in exports, unsupported, or deprecated types are omitted. 
 
Resource types are used whenever you export data, sync across devices, or integrate Insomnia exports with Git or automation workflows. 

### Supported resource types

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

## Resource IDs

Insomnia replaces real UUIDs with special resource IDs when you export, import, or sync workspace data. Insomnia then resolves placeholder special resource IDs automatically when you import exported JSON.

The following table explains Insomnia resource IDs: 

{% table %}
columns:
  - title: Special resource ID
    key: placeholder
  - title: Represents
    key: represents
  - title: Description
    key: description
rows:
  - placeholder: "`__WORKSPACE_ID__`"
    represents: Active workspace identity
    description: Abstract placeholder for the workspace in JSON instead of exposing genuine storage IDs.
  - placeholder: "`__BASE_ENVIRONMENT_ID__`"
    represents: Workspace’s base environment
    description: Abstract placeholder for the workspace’s default environment in exported data.
  - placeholder: "`__<NAME>_<NUMBER>__`"
    represents: Random user-created entities
    description: "Placeholder ID formats that prevent collisions and support consistent ID mapping during imports. For example: `__request_1__`, `__env_2__`"
{% endtable %}

### Special resource IDs

Special resource IDs serve specific internal purposes:
- **Preserve workspace structure**: Maintains logical relationships between workspaces, environments, folders, and requests.
- **Enable safe ID regeneration**: Prevents collisions by replacing fixed IDs with deterministic patterns during import.
- **Support cross-environment reuse**: Makes exported JSON portable across machines or team members without ID conflicts.
- **Obscure internal identifiers**: References entities generically to avoid exposing actual storage-layer IDs.