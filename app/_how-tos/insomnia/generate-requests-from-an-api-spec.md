---
title: Generate requests from an API spec in Insomnia
permalink: /how-to/generate-requests-from-an-api-spec/
content_type: how_to
description: Learn how to add a request to an API Collection for each endpoint in your OpenAPI spec.
products:
    - insomnia

min_version:
  insomnia: "13.3"

tags:
  - collections
  - design-apis

related_resources:
  - text: API Collections
    url: /insomnia/collections/
  - text: API specs in Insomnia
    url: /insomnia/api-specs/
  - text: Create an API Collection in Insomnia
    url: /how-to/create-an-api-collection/
  - text: Import an API specification into an API Collection
    url: /how-to/import-an-api-spec/

tldr: 
  q: How do I generate requests from an API spec?
  a: Add an API spec to an API Collection and define your environment variables, then click the **Spec** tab. If the spec has no linting errors, the **Generate** button appears. Click it and select "Requests". Insomnia adds a request for each endpoint in the spec so you can send requests while you're still working on the design.

prereqs:
  inline:
    - title: An API Collection with a specification
      content: |
        You can either [create an API Collection](/how-to/create-an-api-collection/) and design your specification from scratch, or [import an existing specification](/how-to/import-an-api-spec/). This example uses the [Konnect API Products specification](/api/konnect/api-products/). Make sure that the specification doesn't have any errors, otherwise the requests can't be generated.
      icon_url: /assets/icons/insomnia/design.svg

---

## Configure an environment

If your API specification contains variables, you can use the environment to replace them with actual values in all the generated requests.

1. Click **Base Environment**.
1. Click the pencil icon to open the **Manage Environment** window.
1. [Define the environment variables](/insomnia/environments/) you need. In this example, you need to define at least the base URL and [Personal Access Token](/konnect-api/#personal-access-tokens):

    ```json
    {
      "base_url": "https://us.api.konghq.com/v2",
      "bearerToken": "YOUR_PAT_TOKEN"
    }
    ```

## Generate requests

1. Open your API Collection and click the **Spec** tab.
1. Click **Generate**.
1. From the **Generate** dropdown menu, select "Requests".

Insomnia adds a request for each endpoint in your specification. The requests display in the sidebar under your API Collection.

If the operations in the API spec have tags, the requests are organized into folders based on these tags. If an operation has multiple tags, the request is duplicated and appears in each folder. You can reorganize the requests as needed. For more information, see [API Collections](/insomnia/collections/).

{:.info}
> {% new_in 13.3 %} Generated requests live in the same API Collection as the spec, so you can reach them from the sidebar and from the **Collections** list. In Insomnia 13.2 and earlier, a collection generated from a design document was only reachable from the **COLLECTION** tab of that document.

## Send requests

If the necessary environment variables are set, you can send a request right away. In this example using the [Konnect API Products specification](/api/konnect/api-products/), you can send the *List API Products* request with only the base URL and Bearer token defined:

![Insomnia request with 200 status code](/assets/images/insomnia/generate-collection-request.png)
