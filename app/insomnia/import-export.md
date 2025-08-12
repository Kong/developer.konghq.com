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
    url: /inso-cli/cli-command-reference
  - text: Design documents
    url: /insomnia/get-started-with-documents
  - text: Insomnia Storage Options
    url: /insomnia/insomnia-storage-options-guide

faqs:
  - q: 
    a: |

---

Insomnia supports importing and exporting design documents, collections, requests, and scoped data with the desktop UI and OpenAPI specs through CLI. Use these paths to move, to share, or to automate API workflows.

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
    method: `inso lint spec <identifier>` in CI to lint OpenAPI and fail builds on errors. :contentReference[oaicite:1]{index=1}
  - use_case: Automate test execution from Insomnia test suites in CI
    method: `inso run test <identifier>` to run defined tests and return pass/fail exit codes. :contentReference[oaicite:2]{index=2}  
{% endtable %}

## Import methods

Depending on your workflow requirements, you can import API definitions into Insomnia with either of the following methods:
- UI import
- CLI import

### UI import
In a workspace or document header, select **Import** and how you'd like to import:
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

### CLI import
Use Inso CLI to supplement UI workflows with command-line capabilities focused on API spec-focused automation. For more information about about Inso CLI, go to our [reference page](https://developer.konghq.com/inso-cli/).

## Export methods

Insomnia supports flexible export options that are tailored to both manual and automated workflows. You can either use the desktop app, ideal for immediate data transfer or archival, or employ the Inso CLI to script OpenAPI specification exports within CI pipelines.

### UI export
- Via **Import/Export** menu or **Preferences → Data**: Export Document, Project, or all data.  
  Supported formats include Insomnia JSON (v4/v5), HAR, and others.  
  :contentReference[oaicite:3]{index=3}

### CLI export (Inso)
- Use `inso export spec [identifier] --output <path>` to export the raw OpenAPI specification from a design document. Defaults to console if `--output` omitted.  
  :contentReference[oaicite:4]{index=4}

## Supported formats

- **Import formats**: Insomnia JSON, Postman v2.0/v2.1, HAR, OpenAPI 3.0/3.1, Swagger, WSDL, cURL  
  :contentReference[oaicite:5]{index=5}
- **Export formats**:
  - Insomnia JSON (v5) – full fidelity project export
  - HAR – network data archive
  - OpenAPI via Inso CLI for design documents
  :contentReference[oaicite:6]{index=6}

## Notes and behaviors

- **Environment variables visibility**: Nested environment variables may not show in Table view; switch to JSON view helps.
- **File extension handling**: Some exports (especially on Linux with Flatpak) may omit `.json`; append manually if needed.  
  :contentReference[oaicite:8]{index=8}
- **Scope control**: “Export all data” bundles entire data; individual scope exports (document, project) yield narrower sets.

## Related resources

- **Import and Export Data** – comprehensive UI-based import/export guide  
  `/insomnia/import-export-data` :contentReference[oaicite:9]{index=9}
- **Inso CLI reference** – list of CLI commands including `export spec`  
  `/inso-cli/cli-command-reference` :contentReference[oaicite:10]{index=10}
- **Design documents intro** – what design documents are and how to use them  
  `/insomnia/get-started-with-documents` :contentReference[oaicite:11]{index=11}
- **Storage Options** – control where workspaces are saved and synced  
  `/insomnia/insomnia-storage-options-guide` :contentReference[oaicite:12]{index=12}
