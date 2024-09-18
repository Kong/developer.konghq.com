---
title: Generate a collection from an API specification

products:
    - insomnia

tags:
  - collections
  - documents

tldr: 
  q: How do I generate a collection from an API spec?
  a: Create or import an API spec and define environment variables, then click cog icon and click Generate collection.

prereqs:
  inline:
    - title: Create an API specification
      content: |
        You can either [create an empty document]() and design your specification from scratch, or [import an existing specification](). This example uses the [Konnect API Products specification](https://docs.konghq.com/konnect/api/api-products/latest/).

---

## 1. Configure an environment

If your API specification contains variables, you can use the environment to replace them with actual value in all the requests in your collection.

Click **Base Environment**, then click the pencil icon to open the **Manage Environment** window and [define the environment variables]() you need. In this example, we need to define at least the base URL and token:

```json
{
	"base_url": "https://us.api.konghq.com/v2",
	"bearerToken": "<my token>"
}
```

## 2. Generate a collection

Open your document and click the cog icon next to the **Preview** button. A collection of requests in created in the **COLLECTION** tab. 

If the operations in the API spec have tags, the requests are organized into folders based on these tags. If an operation has multiple tags, the request is duplicated and appears in each folder. You can reorganize the requests as needed. For more information, see [Collections]().

{:.info}
> Since this collection is linked to a document, it cannot be accessed from the **Collections** list. You can find it in the **COLLECTION** tab of your document.