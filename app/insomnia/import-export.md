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
  - q: Why aren’t all environment variables visible in the table view?
    a: |
      Nested environment variables may not appear in the table view. 
      If this happens, switch to the **JSON** view to see the full environment variable structure.

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

## Import methods

Depending on your workflow requirements, you can import into Insomnia with either of the following methods:
- UI import
- CLI import

### UI import


In a workspace or document header, select **Import** and then specify your import method:
- File
- URL
- Clipboard

Insomnia supports the following import formats:
- **Import formats**: Insomnia JSON (v4), Insomnia YAML (v5), Postman v2.0/v2.1, HAR, OpenAPI 3.0/3.1, Swagger, WSDL, and cURL
- **Export formats (UI)**: Insomnia YAML (v5) and HAR
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
- Insomnia v5 (YAML)
- HAR

### CLI export
Use Inso CLI to automate exports of your OpenAPI specification from a design document. You can write the spec to a file, or let the CLI print to standard output for piping in scripts and CI. For a full overview, see the Inso CLI reference.

An example of the key commands:
* **Export an OpenAPI spec to a file**
  
  Use `inso export spec "<Design Document Name>" --output spec.yaml` to extract the raw OpenAPI specification tied to a design document and save it to a file. The identifier can be the spec name or its ID.

* **Export to standard output for piping**
  
  Use `inso export spec "<Design Document Name>"` without `--output` to print the spec to the console. This is useful for shell redirection or piping into other tools. 

## v4 and v5 file formats

Insomnia exports in the v5 file format and can still import legacy v4 JSON files. The two formats are structured differently, as described in the following tabs.

{% navtabs "file-format" %}
{% navtab "v5 (YAML)" %}

The v5 file format is a native YAML format that Insomnia generates in the following cases:

* When you export a collection, design document, environment, or mock server.
* When you use [Git Sync](/insomnia/storage/#git-sync): Insomnia writes your project data to the Git repository as v5 files.

Each v5 file represents a single entity and identifies itself with a top-level `type` field.

**File types**

The `type` field at the top of each file tells you what kind of file it is:

{% table %}
columns:
  - title: "`type` value"
    key: type
  - title: File
    key: file
rows:
  - type: "`collection.insomnia.rest/5.0`"
    file: Request collection
  - type: "`spec.insomnia.rest/5.0`"
    file: API spec / design document
  - type: "`mock.insomnia.rest/5.0`"
    file: Mock server
  - type: "`environment.insomnia.rest/5.0`"
    file: Global environment
  - type: "`mcpClient.insomnia/5.0`"
    file: MCP client
{% endtable %}

Alongside `type`, each file includes top-level fields such as `name`, `schema_version`, and `meta.id`, plus keys specific to the file type (for example, `collection`, `spec` and `testSuites`, or `server` and `routes`).

The version in the `type` value (`5.0`) identifies the file format, while `schema_version` and the JSON Schema file name (for example, `5.1`) track revisions to the schema. These version numbers are independent and don't need to match.

**Example**

The following is a trimmed example of a request collection file. The top-level `type` marks it as a collection, and the `collection` key holds the requests:

```yaml
type: collection.insomnia.rest/5.0   # Identifies the file as a request collection
schema_version: "5.1"                # Schema revision the file conforms to
name: Requests
meta:
  id: wrk_abfeee3c2bf2424bbbff129034019aa9
collection:                          # Type-specific key: the requests in the collection
  - name: List pets
    url: https://api.example.com/pets
    method: GET
environments:
  name: Base Environment
```

**JSON Schema**

Insomnia publishes a [JSON Schema](https://raw.githubusercontent.com/Kong/insomnia/develop/schemas/insomnia.schema.5.1.json) that describes the structure of v5 files. The schema describes the shape of the files; it doesn't contain any data.

Each schema version has its own file, named `insomnia.schema.<version>.json`, with its own link.

You can use the schema to:

* **Validate and autocomplete while editing**: Point your editor at the schema to get autocompletion, inline documentation, and validation as you hand-edit v5 files. For example, in VS Code with the YAML extension, map the schema to your Insomnia files in `settings.json`:

  ```json
  {
    "yaml.schemas": {
      "https://raw.githubusercontent.com/Kong/insomnia/develop/schemas/insomnia.schema.5.1.json": "**/*.yaml"
    }
  }
  ```

  In this mapping, the key is the schema URL and the value (`**/*.yaml`) is a file glob that selects which files the schema applies to. Adjust that glob to match only your Insomnia files, so the schema isn't applied to unrelated YAML in your workspace.

* **Validate files in CI**: Because v5 files are stored in your Git repository when you use Git Sync, you can validate them in a pipeline so that a malformed edit fails the build:

```sh
curl -O https://raw.githubusercontent.com/Kong/insomnia/develop/schemas/insomnia.schema.5.1.json && npx ajv-cli validate --spec=draft2020 -s insomnia.schema.5.1.json -d "**/*.yaml"
```

{% endnavtab %}
{% navtab "v4 (JSON)" %}

{:.info}
> The v4 (JSON) format is legacy. Insomnia exports in the v5 file format, but you can still import v4 JSON files.

The v4 format is a single JSON document with a flat `resources` array. Each object in the array carries a `_type` field (for example, `workspace`, `request`, `environment`, `folder`, `response`, `mock`, `plugin`, or `test`) that tells Insomnia what kind of entity it represents.

Real UUIDs are replaced with special resource IDs that preserve workspace structure, prevent identifier collisions, and keep the export portable. Insomnia resolves these placeholders automatically on import:

{% table %}
columns:
  - title: Special resource ID
    key: placeholder
  - title: Represents
    key: represents
rows:
  - placeholder: "`__WORKSPACE_ID__`"
    represents: The active workspace.
  - placeholder: "`__BASE_ENVIRONMENT_ID__`"
    represents: The workspace's base environment.
  - placeholder: "`__<NAME>_<NUMBER>__`"
    represents: "User-created entities, for example `__request_1__` or `__env_2__`."
{% endtable %}

{% endnavtab %}
{% endnavtabs %}