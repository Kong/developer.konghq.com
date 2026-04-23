---
title: Run in Insomnia

description: "Reference for constructing deep-link URLs that open Insomnia to an imported request."

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/

tags:
- import

related_resources:
  - text: Import and export data in Insomnia
    url: /insomnia/import-export/
  - text: API specs in Insomnia
    url: /insomnia/api-specs/
  - text: MCP clients in Insomnia
    url: /insomnia/mcp-clients-in-insomnia/

faqs:
- q: Do I need to sign in to Insomnia to import a request from a URL?
  a: Yes, you must be signed in to Insomnia.
---

## Overview

Use the `https://app.insomnia.rest/run` URL scheme to deep-link into the Insomnia desktop app and open a pre-imported request. You can embed this URL as a button or link in documentation, `readme.md`, or API references.

## URL parameters

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: "`specUrl`"
    description: A full URL to an OpenAPI specification in raw JSON or YAML format
  - parameter: "`endpoint`"
    description: "A `{method},{specPath}` pair (e.g. `GET,/api/v1/users/{userId}`)"
  - parameter: "`operationId`"
    description: "An operation ID from an OpenAPI specification (e.g. `get-flight-by-number`)"
  - parameter: "`curl`"
    description: A url-encoded cURL command to be imported as a single request
  - parameter: "`mcp`"
    description: "A full URL to an MCP server endpoint (e.g. `https://mcp.slack.com/mcp`)"
{% endtable %}

### Example

```txt
https://app.insomnia.rest/run?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml
```

## Embedding the URL

### HTML link

```html
<a href="https://app.insomnia.rest/run?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml">Run in Insomnia</a>
```

### Markdown link

```txt
[Run in Insomnia](https://app.insomnia.rest/run?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml)
```

### Markdown image button

```txt
[![Run in Insomnia](https://insomnia.rest/images/run.svg)](https://app.insomnia.rest/run?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml)
```
