---
title: Import an API specification into an API Collection in Insomnia
permalink: /how-to/import-an-api-spec/
content_type: how_to

products:
    - insomnia

min_version:
  insomnia: "13.3"

description: Import an API specification into Insomnia from a file, URL, or your clipboard.

tags:
  - design-apis

tldr: 
  q: How do I create an API Collection from an existing API spec?
  a: In your Insomnia workspace, click **Import**, choose between importing from a file, a URL, or your clipboard, and click **Scan**. Insomnia creates an API Collection and puts the spec in its **Spec** tab.

faqs:
  - q: Can I import a GraphQL API spec in Insomnia?
    a: Yes. For Insomnia to autodetect that your spec is in GraphQL format, the path must be `/graphql`, the method must be `POST`, the request body must be application/json and must contain a property query with the type string, and the response body must be application/json.
  - q: Where does my spec go after I import it?
    a: "Insomnia creates an API Collection for the spec and puts the spec in the **Spec** tab of that API Collection. In Insomnia 13.2 and earlier, this was a separate workspace type called a design document. For more details, see [API Collections](/insomnia/collections/)."

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
  - text: API Collections
    url: /insomnia/collections/
  - text: Create an API Collection in Insomnia
    url: /how-to/create-an-api-collection/
  - text: Import and export reference for Insomnia
    url: /insomnia/import-export/  
---

## Select a specification

1. In your workspace, click **Import**.
1. Select the source of the import: **File**, **URL**, **cURL**, or **Clipboard**.
1. Based on the source you selected, either choose a file, enter a URL, or paste your API specification.

{:.info}
> Insomnia automatically detects cURL commands and converts them into requests.

## Scan the specification

1. Click **Scan**.
1. Review the resources to import.
1. Click **Import**.

Insomnia creates an API Collection for your specification and puts the specification in its **Spec** tab.

## Validate

Open the imported API Collection and click the **Spec** tab. You can see three different views:

* On the left you can see an overview of the specification, with sections that you can expand. You can click the different elements to highlight them in the specification.
* In the middle, you can see the specification as it was imported. You can also see if there are any warnings or errors.
* On the right, you can see a preview of the rendering of the specification.

![API spec in the Spec tab of an API Collection](/assets/images/insomnia/design-document.png)

To turn the specification into requests you can send, click **Generate** and select "Requests". For more information, see [Generate requests from an API spec](/how-to/generate-requests-from-an-api-spec/).
