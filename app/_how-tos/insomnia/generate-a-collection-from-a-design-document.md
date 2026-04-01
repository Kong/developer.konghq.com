---
title: Generate a collection from a design document
permalink: /how-to/generate-a-collection-from-a-design-document/
content_type: how_to
description: Learn how to generate a request collection from an existing design document.
products:
    - insomnia

tags:
  - insomnia-documents
  - collections

tldr: 
  q: How do I generate a collection from an API spec?
  a: Create or import an API spec as a design document and define environment variables, then click settings icon and click **Generate collection**. Generating a collection from a document allows you to test your requests while still working on the design.

prereqs:
  inline:
    - title: Create an API specification
      content: |
        You can either [create an empty document](/how-to/create-a-design-document/) and design your specification from scratch, or [import an existing specification](/how-to/import-an-api-spec-as-a-document/). This example uses the [Konnect API Products specification](/api/konnect/api-products/). Make sure that the specification doesn't have any errors, otherwise the collection can't be generated.
      icon_url: /assets/icons/insomnia/design.svg

---

## Configure an environment

If your API specification contains variables, you can use the environment to replace them with actual value in all the requests in your collection.

Click **Base Environment**, then click the pencil icon to open the **Manage Environment** window and [define the environment variables]() you need. In this example, we need to define at least the base URL and token:

```json
{
	"base_url": "https://us.api.konghq.com/v2",
	"bearerToken": "MY TOKEN"
}
```

## Generate a collection

Open your document and click the settings icon next to **Preview**. Click **Generate collection**. A collection of requests in created in the **COLLECTION** tab. 

If the operations in the API spec have tags, the requests are organized into folders based on these tags. If an operation has multiple tags, the request is duplicated and appears in each folder. You can reorganize the requests as needed. For more information, see [Collections]().

{:.info}
> Since this collection is linked to a document, it cannot be accessed from the **Collections** list. You can find it in the **COLLECTION** tab of your document.

## Send requests

If the necessary environment variables are set, you can send a request right away. In this example using the [Konnect API Products specification](/api/konnect/api-products/), we can send the *List API Products* request with only the base URL and Bearer token defined:

![Insomnia request with 200 status code](/assets/images/insomnia/generate-collection-request.png)