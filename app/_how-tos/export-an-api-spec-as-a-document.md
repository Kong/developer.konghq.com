---
title: Export a design document in Insomnia
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
    a: Select the collection drop-down menu, then **Export**, from here you can select an individual request.
prereqs:
  inline:
    - title: An Insomnia design document
      content: |
        You need to have an Insomnia design document. For instructions on creating one see [Create a design document](/how-to/create-a-design-document/)
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
You can export the following files from Insomnia:
- API design document
- Collection
- Request
This tutorial will explain how to export a document. 
## Export a file

To export a file from Insomnia, navigate to your workspace:
1. Click **Preferences**, and then click **Data**.
2. Select an export option:
    - **Export the "name of file" Document**: Export a single, specific API design document.
    - **Export the "project name" Project**: Export a project, including all associated API requests, design documents, and tests.
    - **Export all data**: Export all data from your all your workspaces.
    - **Create Run Button**: Create a sharable button that, when clicked, automatically opens a specific request or collection in the Insomnia application and executes it.
3. Click **Export**.
4. Choose a format to export the file as:
    - **Insomnia v5**: A native JSON export format that contains the full structure of Insomnia projects, including requests, environments, metadata, and documentation.
    - **HAR - HTTP Archive Format**: A standardized, JSON‑based log of HTTP requests and responses that is used primarily for network-level debugging and performance analysis. 
5. Click **Done**.
