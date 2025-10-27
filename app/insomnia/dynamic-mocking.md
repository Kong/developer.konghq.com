---
title: Dynamic Mocking
content_type: reference
layout: reference

products:
 - insomnia

tags:
- mock-servers

description: Use dynamic mocking in Insomnia mock servers to return request-aware responses and realistic fake data in self-hosted mocks.

breadcrumbs:
  - /insomnia/

related_resources:
  - text: Mocks
    url: /insomnia/mock-servers/
  - text: Self-hosted mocks
    url: /insomnia/self-hosted-mocks/
  - text: Storage options
    url: /insomnia/storage/
  - text: Requests
    url: /insomnia/requests/
  - text: Template tags
    url: /insomnia/template-tags/     
---

Dynamic mocking extends Insomnia’s existing mock server feature by evaluating templates at request time so responses can change based on the incoming request or defined template logic. You configure routes in Insomnia and serve them from Self-hosted mock servers.

Traditional mocks return static, predefined payloads, while dynamic mocks generate context-aware, variable outputs.

For adding random values, Insomnia provides [**Faker template tags**](/insomnia/template-tags/) that you can insert anywhere that tags are supported.

Use Dynamic mocking to:
- **Serve request-aware responses**: Configure a mock route that adapts to request headers and shape the response based on the incoming request. For example, echoing identifiers or switching fields. You manage this for each route.
- **Insert random data with template tags**: Use Insomnia’s Faker template tags to generate values such as names, emails, timestamps, and UUIDs.

{:.info}
> The headers and status remain configured per route.

## Dynamic capabilities

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: option
  - title: Description
    key: description
rows:
  - option: Use request data
    description: |
      Access details from the incoming request and reflect them in the mock response.  
      For example, echo a query parameter or include a field from the request body.  
      This makes the mock behave more like a live API.
  - option: Apply conditional logic
    description: |
      Use simple Liquid conditions to vary the response based on the request.  
      Only a limited set of Liquid tags are supported for safety.
  - option: Generate fake data
    description: |
      Insert random but realistic data, such as names, emails, or timestamps.  
      Use [**Faker template tags**](/insomnia/template-tags/) anywhere template tags are supported.
  - option: Combine request and fake data
    description: |
      Mix request data with generated values for realistic scenarios.  
      For example, include the requester’s ID with random profile data.
{% endtable %}
<!-- vale on -->

- Faker usage follows Insomnia’s template tag model. To see Faker details, go to **Template tags**.
- Liquid behavior follows the LiquidJS docs; Insomnia enables a **subset**. For example, `assign`, `if`, `unless`, `raw` for mocks.

## Enable dynamic mocking

Use dynamic templates when defining a mock route’s response body:

1. Create or open a mock server and add a **route**.
1. In **Response body**, enter a **Liquid** template that reads `req.*` and/or `faker.*`.
1. (Optional) Set **Status** and **Headers** for the route.
1. Send a request to the mock route and verify the rendered output.

> Self-hosted mocks run the published container image from the repository.
