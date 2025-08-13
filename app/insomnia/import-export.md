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
  - cli

description: Learn how to import and export data in Insomnia using the UI and the Inso CLI, and which formats are supported.

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
---

Insomnia offers a unified workflow for importing and exporting API artifacts. Whether you're using the desktop UI or automating tasks via the Inso CLI, this page outlines the methods, their compatibility, and practical use cases to fit a variety of developer workflows.

## Typical use cases

{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Method
    key: method
rows:
  - use_case: Export a design document for version control
    method: UI export from document menu or Preferences; or `inso export spec` for OpenAPI.
  - use_case: Transfer all API work to another machine
    method: UI → Preferences → Data → Export all data.
  - use_case: Import a Postman collection or OpenAPI spec into Insomnia
    method: UI → Import → choose File/Clipboard/URL.
  - use_case: Integrate spec validation into CI pipelines
    method: |
      `inso lint spec <identifier>` in CI to lint OpenAPI and fail builds on errors. :contentReference[oaicite:1]{index=1}
  - use_case: Automate test execution from Insomnia test suites in CI
    method: |
      `inso run test <identifier>` to run defined tests and return pass/fail exit codes. :contentReference[oaicite:2]{index=2}  
{% endtable %}

## Import methods

Depending on your workflow requirements, you can import API definitions into Insomnia with either of the following methods:
- UI import
- CLI import

### UI import
In a workspace or document header, select **Import** and then specify your method:
- file
- URL
- clipboard
Our UI method Supports:
- Insomnia JSON
- Postman v2
- HAR
- OpenAPI/Swagger
- WSDL
- cURL
For more information on importing with the UI, go to [how to import an API spec as a document](https://developer.konghq.com/how-to/import-an-api-spec-as-a-document/).

### CLI import
Use Inso CLI to supplement UI workflows with command-line capabilities. Instead of importing files into the application directly, you can use Inso CLI to run tests, execute collections, validate specs, export OpenAPI artifacts, and run custom scripts.

An example of our key commands:
- |
Execute test suites via CLI
Use `inso run test "<Design Document Name>" --env "<Environment Name>"` to run unit tests defined in the Insomnia app. The execution runs as in CI pipelines and returns a non-zero exit code if tests fail.
- |
Validate an OpenAPI specification
Use `inso export spec "<Design Document Name>" --output <filename>.yaml` to extract the raw OpenAPI spec tied to a design document. Without `--output`, the CLI prints the spec to stdout for easy scripting.
- |
Run request collections automatically
Use `inso run collection "<Collection Name>" --env "<Environment Name>"` to batch-run all requests and scripts in a collection. This is ideal for automation and guarantees consistency across environments.

For more information, go to our [reference page](https://developer.konghq.com/inso-cli/).

## Export methods

Insomnia supports flexible export options that are tailored to both manual and automated workflows. You can either use the desktop app, ideal for immediate data transfer or archival, or use Inso CLI to script OpenAPI specification exports within CI pipelines.

### UI export
In a workspace or document header, select **Export**  and then specify the file type:
- Document: Export only the active design document. This includes the requests, environment settings, and tests. It does not include other workspace data.
- Project: Export the selected collection. This includes all contained requests and environments.
- all data: Export everything in your workspace.
Our UI method supports the following formats:
- Insomnia JSON (v4/v5)
- HAR

For more information on exporting with the UI, go to [how to export an API spec as a document](https://developer.konghq.com/how-to/export-an-api-spec-as-a-document/).


### CLI export
Use Inso CLI to automate exports of your OpenAPI specification from a design document. You can write the spec to a file, or let the CLI print to standard output for piping in scripts and CI. For a full overview, see the Inso CLI reference.

An example of our key commands:
- |
Export an OpenAPI spec to a file
Use `inso export spec "<Design Document Name>" --output spec.yaml` to extract the raw OpenAPI specification tied to a design document and save it to a file. The identifier can be the spec name or its ID. 
- |
Export to standard output for piping
Use `inso export spec "<Design Document Name>"` without `--output` to print the spec to the console. This is useful for shell redirection or piping into other tools. 
- |
Notes about identifiers and prompts
If you omit the identifier, Inso prompts you to select a spec interactively; in CI, pass a name or ID to avoid prompts. 

## Supported formats

- **Import formats**: Insomnia JSON, Postman v2.0/v2.1, HAR, OpenAPI 3.0/3.1, Swagger, WSDL, and cURL.
- **Export formats (UI)**: Insomnia JSON (v4/v5), HAR.
- **Export formats (CLI)**: OpenAPI spec via `inso export spec`.

## Notes and behaviors

- **Environment variables visibility**: Nested environment variables may not show in Table view; switch to JSON view helps.
- **File extension handling**: Some exports (especially on Linux with Flatpak) may omit `.json`; append manually if needed.
- **Scope control**: “Export all data” bundles entire data; individual scope exports (document, project) yield narrower sets.
