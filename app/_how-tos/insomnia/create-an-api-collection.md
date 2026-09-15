---
title: Create an API Collection in Insomnia
permalink: /how-to/create-an-api-collection/
content_type: how_to
description: Create an API Collection in the Insomnia app, then add an OpenAPI spec to it from the Spec tab.
products:
    - insomnia
min_version:
  insomnia: "13.3"
breadcrumbs:
  - /insomnia/collections/
tags:
  - insomnia-documents
  - design-apis
related_resources:
  - text: About Insomnia
    url: /insomnia/
  - text: API Collections
    url: /insomnia/collections/
  - text: API specs in Insomnia
    url: /insomnia/api-specs/
  - text: Import an API specification into an API Collection
    url: /how-to/import-an-api-spec/
  - text: Generate requests from an API spec in Insomnia
    url: /how-to/generate-requests-from-an-api-spec/
tldr:
  q: How do I create an API Collection?
  a: In your Insomnia workspace, click **Create** > **API Collection**, enter a name, and click **Create**. To add an OpenAPI spec, click the **Spec** tab, then write your spec or click **Use example OpenAPI Spec**.
---

## Create an API Collection

An API Collection holds your requests, folders, environments, and an optional OpenAPI spec.

1. In your workspace, click **Create**.
1. From the **Create** dropdown menu, select "API Collection".
1. In the **Name** field, enter `Flights Service`.
1. Click **Create**.

Your new API Collection opens.

{:.info}
> {% new_in 13.3 %} Documents and collections are merged into a single workspace type called an API Collection, so **Create** > **Design document** is no longer in the UI. Create an API Collection instead, then add your spec to it. For more details, see [API Collections](/insomnia/collections/).

## Add an OpenAPI spec

You can design an API in the same API Collection that you use to call it.

1. On the API Collection screen, click the **Spec** tab.
1. Click **Use example OpenAPI Spec** to populate the spec editor with the sample _Swagger Petstore_ specification.

To write your own spec instead, enter it directly in the spec editor. To start from a spec you already have, see [Import an API specification into an API Collection](/how-to/import-an-api-spec/).

## Validate

On the **Spec** tab, confirm that you can see the three panes of the spec editor:

* On the left, an overview of the specification, with sections that you can expand. Click an element to highlight it in the specification.
* In the middle, the specification itself, along with any warnings or errors.
* On the right, a preview of the rendered specification.

To turn the spec into requests you can send, click **Generate** and select "Requests". For more information, see [Generate requests from an API spec](/how-to/generate-requests-from-an-api-spec/).
