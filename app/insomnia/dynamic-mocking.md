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

Dynamic mocking extends Insomnia’s existing mock server feature by evaluating templates at request time so responses can change based on the incoming request or defined template logic. You configure routes in Insomnia and serve them from Self-hosted mock servers. Headers and status codes remain configured per route, which ensures consistency while response data updates dynamically.

Traditional mocks return static, predefined payloads, while dynamic mocks generate context-aware, variable outputs.

For adding random values, Insomnia provides [**Faker template tags**](/insomnia/template-tags/) that you can insert anywhere that tags are supported.

Use dynamic mocking to:
- **Serve request-aware responses**: Configure a mock route that adapts to request headers and shape the response based on the incoming request. For example, echoing identifiers or switching fields. You manage this for each route.
- **Insert random data with template tags**: Use Insomnia’s Faker template tags to generate values like names, emails, timestamps, and UUIDs.

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
      Only a limited set of Liquid tags are supported for safety.
  - option: Generate fake data
    description: |
      Insert random but realistic data, such as names, emails, or timestamps.  
      Use [**Faker template tags**](/insomnia/template-tags/) anywhere template tags are supported.  
  - option: Combine request and fake data
    description: |
      Mix request data with generated values for realistic scenarios. For example, include the requester’s ID with random profile data.
{% endtable %}
<!-- vale on -->

## Template reference examples

Dynamic mocking in Insomnia supports a limited but powerful set of Liquid template tags and logic controls. These enable variable responses, conditional behavior, and safe data generation.

Faker usage follows Insomnia’s template tag model. You can use Faker functions anywhere template tags are supported to generate realistic mock data like names, emails, or timestamps.

For a complete list of available Faker properties, go to [**faker-functions.ts**](https://github.com/Kong/insomnia/blob/develop/packages/insomnia/src/templating/faker-functions.ts).

### Liquid logic control

Logic control in dynamic mocking is based on Liquid’s templating language; it only supports a subset of built-in tags for safety and simplicity.

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
    ref: "[LiquidJS Assign](https://liquidjs.com/zh-cn/tags/assign.html)"
  - tag: "`if`"
    description: "Conditionally renders a block of content when a statement evaluates as true."
    ref: "[LiquidJS If](https://liquidjs.com/zh-cn/tags/if.html)"
  - tag: "`unless`"
    description: "Renders a block when a statement evaluates as false; acts as the inverse of `if`."
    ref: "[LiquidJS Unless](https://liquidjs.com/zh-cn/tags/unless.html)"
  - tag: "`raw`"
    description: "Prevents Liquid from interpreting enclosed content. Use this to escape template syntax within mock responses."
    ref: "[LiquidJS Raw](https://liquidjs.com/zh-cn/tags/raw.html)"
{% endtable %}
<!-- vale on -->

For additional implementation details and syntax behavior, go to the [**LiquidJS documentation**](https://liquidjs.com/zh-cn/).

### Use data from requests

You can access values from incoming requests and include them in your mock responses.

**Format to output a variable:**

```liquid
{% raw %}
{{ req.headers['Content-Type'] }}
{{ req.body.name }}
{% endraw%}
```

**Format to define a default value:**

```liquid
{% raw %}
{{ req.body.name | default: "George" }}
{% endraw%}
```

**Available variables**

- `req.headers.*` — Reference a specific request header  
- `req.queryParams.*` — Reference query parameters in the URL  
- `req.pathSegments[*]` — Reference specific segments of the URL path  
- `req.body` — Returns the full request body (only when the body is not a binary stream)  
- `req.body.*` — When the content type is `application/json`, `application/x-www-form-urlencoded`, or `multipart/form-data`, Insomnia parses the body and exposes each field  

### Generate random data

Use Faker template tags to generate random but realistic data in mock responses.

**Format to output random data:**

```liquid
{% raw %}
{{ faker.randomFullName }}
{% endraw%}
```

## Use dynamic mocking

1. In the body of your Mock route request, enter a **Liquid** template that reads `req.*` and/or `faker.*`.  
2. (Optional) Set **Status** and **Headers** for the new mock route.  
3. Click **Test**.

> Self-hosted mocks run the published container image from the repository.

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