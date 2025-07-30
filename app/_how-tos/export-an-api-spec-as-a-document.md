---
title: Export your API design document or request data
content_type: how_to

products:
  - insomnia

description: Export a design document, collection, or single request from Insomnia.

tags:
  - documents

tldr:
  q: How do I export an API design document, collection, or a request in Insomnia?
  a: In your workspace, open the Document or Collection menu, click **Preferences → Data**, select the target format and scope, and then export the file.

faqs:
  - q: Can I export just one request?
    a: Yes. Click **Export Data → Single Request** from the Document or Collection menu or click  **Preferences → Data**. Then select just that request.
prereqs:
  inline:
    - title: API specification
      content: |
        You need to have an API specification in one of the following formats:
          * Insomnia
          * Postman v2
          * HAR
          * OpenAPI (versions 3.0, 3.1)
          * Swagger
          * WSDL
          * cURL
      icon_url: /assets/icons/code.svg

related_resources:
  - text: API specs in Insomnia
    url: /insomnia/api-specs/
  - text: Design documents
    url: /insomnia/documents/
  - text: Import an API specification as a design document in Insomnia
    url: /how-to/import-an-api-spec-as-a-document/
  - text: Resource types reference
    url: /insomnia/resource-types-reference/   
  - text: Special resource IDs
    url: /insomnia/special-resource-ids/    
---
Export your API design documents from Insomnia to capture the exact endpoints and schemas that you use, ensuring accurate documentation, seamless teamwork, and easy integration with tools such as [Inso CLI](/inso-cli/) or CI/CD workflows.

You can export the following formats from Insomnia:
- API design document
- Collection
- Request

## Export

To export a file from Insomnia, navigate to your workspace:
1. Click **Preferences**, and then click **Data**
2. Select an export option:
    - **Export the 'name of file' Document**: Export a single, specific API design document.
    - **Export the 'project name' Project**: Export a project, including all associated API requests, design documents, and tests.
    - **Export all data**: Export all data from your all your workspaces.
    - **Create Run Button**: Create a sharable button that, when clicked, automatically opens a specific request or collection in the Insomnia application and executes it.
3. Click **Export**.
4. Choose a format to export the file as:
    - **Insomnia v5**: A native JSON export format that contains the full structure of Insomnia projects, including requests, environments, metadata, and documentation.
    - **HAR - HTTP Archive Format**: A standardized, JSON‑based log of HTTP requests and responses that is used primarily for network-level debugging and performance analysis. 
5. Click **Done**.

### Special resource IDs
To ensure workspace identity is preserved at import and avoid collisions, exported Insomnia files include placeholder resource IDs like `__WORKSPACE_ID__` and `__BASE_ENVIRONMENT_ID__`. Insomnia replaces these during import to reconstruct the structure accurately. These IDs are automatically handled by the tool—no user editing necessary.

For more information, refer to our [Special resource IDs] () reference page.

### Resource types
The export file includes a `data.resources` object with a `resources` array, each element represents an object of a specific resource type:
- `_type` field indicates the kind: `workspace`, `environment`, `request`, `response`, `folder`.
- Only supported resource types defined in Insomnia’s schema are included; internal metadata or auxiliary data is typically excluded.
These resource types determine what you create when you import. If a resource type is omitted or unsupported, the related element won't appear in the reconstructed workspace.