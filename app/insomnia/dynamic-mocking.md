---
title: Dynamic Mocking
content_type: reference
layout: reference

products:
 - insomnia

tags:
- mock-servers

description: Use dynamic mocking in Insomnia mock servers to return request-aware responses and realistic mock data.

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

Dynamic mocking extends Insomnia’s existing mock server feature. For each request, dynamic mocking renders Liquid templates so responses can include:

- Data from the request (headers, query parameters, path, or body).
- Randomly generated fake data.

## How to use the Liquid template

Use the Liquid template language in the Insomnia app:

1. Open or create a Mock server.
2. Create a new route.
3. Go to the **Mock Body** tab.
4. Define a dynamic response body.

Response headers and status codes remain configured per route, which ensures consistency while the response body updates dynamically.

### Differences from traditional mocks

Traditional mocks return static, predefined payloads, while dynamic mocks generate context-aware, variable outputs:

<!-- vale off -->
{% table %}
columns:
  - title: Mock Body type
    key: type
  - title: Response
    key: response
  - title: Example
    key: example
rows:
  - type: Static
    response: Static, predefined payloads.
    example: |
      The client sends `"name": "George"`, and the mock returns `George`.
  - type: Dynamic
    response: Context-aware, variable outputs.
    example: |
      The client sends `faker.randomFullName`, and the mock returns a randomly generated name.
  - type: Static and Dynamic combined
    response: A mix of fixed fields and dynamic values.
    example: |
      The client sends `faker.randomFullName` together with a fixed `"role": "admin"` field. The mock returns a randomly generated name with the role set to `admin`.
{% endtable %}
<!-- vale on -->

For adding random values, Insomnia provides faker variables that you can insert anywhere in the response body.

Use dynamic mocking to:
- **Serve request-aware responses**: When the mock reads the request and returns different content from it. For example, echoing identifiers or switching fields based on a query parameter or request body.
- **Insert random data with faker variables**: Use faker variables to generate values like names, emails, timestamps, and UUIDs.

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
      Access details from the incoming request and reflect them in the mock response. For example, echo a query parameter or include a field from the request body. 
      This makes the mock behave more like a live API.
  - option: Apply conditional logic
    description: |
      Use simple Liquid conditions to vary the response based on the request.  
      Only a limited subset of Liquid tags is supported for safety.
  - option: Generate fake data
    description: |
      Insert random but realistic data, such as names, emails, or timestamps using faker variables.
  - option: Combine request and fake data
    description: |
      Mix request data with generated values for realistic scenarios. For example, include the requester’s ID with random profile data.
{% endtable %}
<!-- vale on -->

## Template syntax

Dynamic mocking uses [**Liquid**](https://liquidjs.com/tutorials/intro-to-liquid.html) as its templating language. Mock response bodies are rendered as Liquid templates at request time, with two built-in variables available:

- `req` — exposes data from the incoming request, including headers, query parameters, path segments, and body.
- `faker` — exposes a set of data generation functions that produce random but realistic values such as names, emails, and timestamps.

To keep templates safe and predictable, only a limited subset of Liquid tags is supported for logic control. For filters, only the [default filter](https://liquidjs.com/filters/default.html) is supported.


### Use data from requests

You can access values from incoming requests and include them in your mock responses.

**Format to output a variable:**

```liquid
{%- raw -%}
{{ req.headers['Content-Type'] }}
{{ req.body.name }}{% endraw %}
```

**Format to define a default value:**

```liquid
{% raw %}{{ req.body.name | default: "George" }}{% endraw %}
```

**Available variables**

- `req.headers.*` — Reference a specific request header  
- `req.queryParams.*` — Reference query parameters in the URL  
- `req.pathSegments[*]` — Reference specific segments of the URL path  
- `req.body` — Returns the full request body (only when the body is not a binary stream)  
- `req.body.*` — When the content type is `application/json`, `application/x-www-form-urlencoded`, or `multipart/form-data`, Insomnia parses the body and exposes each field  

### Generate random data

Use faker variables to generate random but realistic data in mock responses.

**Format to output random data:**

```liquid
{% raw %}{{ faker.<variable-name> }}{% endraw %}
```

For a complete list of available faker variables, go to [**run.js#L218**](https://github.com/Kong/insomnia-mockbin/blob/04134cf81ce29ae7ffcc7ee13e2ecbce70414a96/lib/routes/bins/run.js#L218). Use the names listed under `fakerFunctions` (such as `guid`, `randomFullName`, `randomPhoneNumber`, etc.). For example:


```liquid
{% raw %}{{ faker.randomFullName }}{% endraw %}
```

### Liquid logic control

Only the following Liquid tags are supported:

<!-- vale off -->
{% table %}
columns:
  - title: Tag
    key: tag
  - title: Description
    key: description
  - title: Reference
    key: ref
rows:
  - tag: "`assign`"
    description: "Creates or updates a variable within the template scope."
    ref: "[Liquid Assign](https://liquidjs.com/tags/assign.html)"
  - tag: "`if`"
    description: "Conditionally renders a block of content when a statement evaluates as true."
    ref: "[Liquid If](https://liquidjs.com/tags/if.html)"
  - tag: "`unless`"
    description: "Renders a block when a statement evaluates as false; acts as the inverse of `if`."
    ref: "[Liquid Unless](https://liquidjs.com/tags/unless.html)"
  - tag: "`raw`"
    description: "Prevents Liquid from interpreting enclosed content. Use this to escape template syntax within mock responses."
    ref: "[Liquid Raw](https://liquidjs.com/tags/raw.html)"
{% endtable %}
<!-- vale on -->

For additional implementation details and syntax behavior, go to the [**LiquidJS documentation**](https://liquidjs.com/).

## The test options for a mock route in the Insomnia app

### Basic test options

{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
  - title: When to use
    key: when
rows:
  - option: "Send now"
    description: "Immediately send a request to the mock server and display the response in the Response pane."
    when: "Use this option for quick validation that your mock routes, dynamic templates, or environment variables resolve correctly. Ideal during early setup or after modifying a mock definition."
  - option: "Generate client code"
    description: "Produce a client-side code snippet that reproduces the current mock request in multiple languages. For example, `curl`, JavaScript `fetch`, or Python `requests`."
    when: "Use this when you want to share or automate the mock request outside Insomnia. For example, add it to test scripts, CI jobs, or SDK examples."
{% endtable %}

### Advanced test options

{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
  - title: When to use
    key: when
rows:
  - option: "Send after delay"
    description: "Schedules the request to execute after a specified delay in milliseconds. The request is queued and sent automatically once the delay expires."
    when: "Use this option to simulate **network latency**, **rate-limited APIs**, or **background task timing**. It helps validate client-side behavior when responses are delayed."
  - option: "Repeat on interval"
    description: "Sends the same request repeatedly on a fixed interval until stopped. Each cycle executes independently, allowing you to observe variable or time-sensitive responses from the dynamic mock."
    when: "Use this to test **dynamic responses**, such as mocks that use Faker data, timestamp generation, or conditional logic. It’s also useful for load, polling, or long-running integration tests."
{% endtable %}