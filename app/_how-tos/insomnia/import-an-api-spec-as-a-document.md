---
title: Import an API specification as a design document in Insomnia
permalink: /how-to/import-an-api-spec-as-a-document/
content_type: how_to

products:
    - insomnia

description: Import an API specification into Insomnia from a file, URL, or your clipboard.

tags:
  - insomnia-documents

tldr: 
  q: How do I create a design document from an existing API spec?
  a: In your Insomnia workspace, click **Import**, choose between importing from a file, a URL, or your clipboard, and click **Scan**.

faqs:
  - q: Can I import a GraphQL API spec in Insomnia?
    a: Yes. For Insomnia to autodetect that your spec is in GraphQL format, the path must be `/graphql`, the method must be `POST`, the request body must be application/json and must contain a property query with the type string, and the response body must be application/json.

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
  - text: Import and export reference for Insomnia
    url: /insomnia/import-export/  
---

## Select a specification

In your workspace, click **Import** and select the source of the import: **File**, **URL**, **cURL**, or **Clipboard**. Based on the source, either choose a file, enter a URL, or copy your API specification.

{:.info}
> Insomnia automatically detects cURL commands and converts them into requests.

## Scan the specification

Click **Scan**. You can review the resources to import, then click **Import**.

## Validate

You can now review the imported document. You can see three different views:

* On the left you can see an overview of the specification, with sections that you can expand. You can click the different elements to highlight them in the specification.
* In the middle, you can see the specification as it was imported. You can also see if there are any warnings or errors.
* On the right, you can see a preview of the rendering of the specification.

![Design document](/assets/images/insomnia/design-document.png)