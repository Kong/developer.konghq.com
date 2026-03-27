---
title: Run in Insomnia
permalink: /how-to/run-in-insomnia/

description: "How to construct a URL that will open Insomnia to an imported request."

content_type: how_to

products:

- insomnia

tldr:
  q: How can I construct a URL that will open Insomnia to an imported request?
  a: |
    Use the `https://app.insomnia.rest/run` URL with parameters to import a spec curl command, or mcp remote endpoint and open it in Insomnia.

faqs:

- q: What options are available for URLs that will open the Insomnia desktop app?
  a: |
    You can deep-link into the Insomnia desktop app using the following options:
      - `specUrl`: a full URL to an OpenAPI specification
      - `endpoint`: a {method},{specPath} pair (e.g. `GET,/api/v1/users/{userId}`)
      - `operationId`: an operation ID from an OpenAPI specification (e.g. `get-flight-by-number`)
      - `curl`: a url-encoded cURL command to be imported as a single request
      - `mcp`: a full URL to an MCP server endpoint
- q: Do I need to sign in to Insomnia to import a request from a URL?
  a: Yes, you must be signed in to Insomnia.
---

## Construct the URL

### Example

```txt
https://app.insomnia.rest/run?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml
```

### Parameters

| Parameter | Description |
| --------- | ----------- |
| `specUrl` | A full URL to an OpenAPI specification in raw JSON or YAML format |
| `endpoint` | A {method},{specPath} pair like `GET,/api/v1/users/{userId}` |
| `operationId` | An operation ID from an OpenAPI specification (e.g. `get-flight-by-number`) |
| `curl` | A url-encoded cURL command to be imported as a single request (e.g. `curl -X GET https://api.kong-air.com/flights/$FLIGHT_NUMBER`) |
| `mcp` | A full URL to an MCP server endpoint (e.g. `https://mcp.slack.com/mcp`) |

## Share the URL as a button or link

You can share the URL as a button or link to open Insomnia to an imported request.

### Examples

#### HTML link

```html
<a href="https://app.insomnia.rest/run?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml">Open in Insomnia</a>
```

[Run in Insomnia](https://app.insomnia.rest/run/?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml)

#### Markdown link

```txt
[Run in Insomnia](https://insomnia.rest/run/?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml)
```

[Run in Insomnia](https://app.insomnia.rest/run/?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml)

#### Markdown image button link

```txt
[![Run in Insomnia](https://insomnia.rest/images/run.svg)](https://insomnia.rest/run/?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml)
```

[![Run in Insomnia](https://insomnia.rest/images/run.svg)](https://insomnia.rest/run/?endpoint=GET,/flights/{flightNumber}&specUrl=https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml)
