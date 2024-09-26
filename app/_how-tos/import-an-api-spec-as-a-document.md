---
title: Import an API specification as a design document in Insomnia
products:
    - insomnia

tags:
  - documents

tldr: 
  q: How do I create a design document from an existing API spec?
  a: In your Insomnia workspace, click **Import**, choose between importing from a file, a URL, or your clipboard, and click **Scan**.

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
---

## 1. Select a specification

In your workspace, click **Import** and select the source of the import: **File**, **URL**, or **Clipboard**. Based on the source, either choose a file, enter a URL, or copy your API specification.

## 2. Scan the specification

Click **Scan**. You can review the resources to import, then click **Import**

## 3. Open the document

Open the document created to check your specification. You can see three different views:

* On the left you can see an overview of the specification, with sections that you can expand. You can click the different elements to highlight them in the specification.
* In the middle, you can see the specification as it was imported. You can also see if there are any warnings or errors.
* On the right, you can see a preview of the rendering of the specification.

![Design document](/assets/images/insomnia/design-document.png)