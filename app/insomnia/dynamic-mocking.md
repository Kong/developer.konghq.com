---
title: Dynamic Mocking
content_type: reference
layout: reference

products:
 - insomnia
works_on:
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

Dynamic mocking lets Insomnia mock servers return responses that can reference request context and include random test data using template tags. You configure routes in Insomnia and serve them from  Self-hosted mock servers.

For adding random values, Insomnia provides [**Faker template tags**](/insomnia/template-tags/) that you can insert anywhere that tags are supported.

Use Dynamic mocking to:
- **Serve request-aware responses**: Configure a mock route and shape the response based on the incoming request. For example, echoing identifiers or switching fields. Manage this per route.
- **Insert random data with template tags**: Use Insomnia’s Faker template tags to generate values such as names, emails, timestamps, and UUIDs.

{:.info}
> The headers and status remain configured per route.

## Dynamic capabilities

<!--vale off-->
{% table %}
columns:
  - title: Capability
    key: cap
  - title: What it enables
    key: what
  - title: Example
    key: example
rows:
  - cap: Use request data
    what: Echo or branch on headers, query params, path segments, or parsed body fields
    example: |
      ```liquid
      {
        "ct": "{{ req.headers['Content-Type'] }}",
        "user": "{{ req.queryParams.user_id }}",
        "id": "{{ req.pathSegments[2] }}",
        "name": "{{ req.body.name | default: "unknown" }}"
      }
      ```
  - cap: Generate fake data
    what: Insert realistic values like names, emails, or timestamps with Faker template tags
    example: |
      ```liquid
      {
        "fullName": "{{ faker.randomFullName }}",
        "email": "{{ faker.randomEmail }}",
        "timestamp": "{{ faker.unixTime }}"
      }
      ```
  - cap: Apply simple logic
    what: Shape the response with a limited subset of Liquid tags (no loops)
    example: |
      ```liquid
      {% assign region = req.queryParams.region | default: "us" %}
      {% if region == "ca" %}
      { "greeting": "Bonjour" }
      {% unless region == "ca" %}
      { "greeting": "Hello" }
      {% endunless %}
      ```
{% endtable %}
<!--vale on-->

- Faker usage follows Insomnia’s template tag model. See **Template tags** for Faker details.
- Liquid behavior follows the LiquidJS docs; Insomnia enables a **subset** (for example, `assign`, `if`, `unless`, `raw`) for mocks.

## Enable dynamic mocking

Use dynamic templates when defining a mock route’s response body:

1. Create or open a mock server and add a **route**.
2. In **Response body**, enter a **Liquid** template that reads `req.*` and/or `faker.*`.
3. (Optional) Set **Status** and **Headers** for the route.
4. Send a request to the mock route and verify the rendered output.

> Self-hosted mocks run the published container image from the repository.
