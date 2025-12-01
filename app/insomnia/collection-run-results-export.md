---
title: Collection run results export

content_type: reference

layout: reference

products:
  - insomnia

tools:
  - inso-cli  

breadcrumbs:
  - /insomnia/

description: Reference information for export modes, redaction behaviour, truncation limits, and output structure when exporting collection run results from Inso CLI.

faqs:
  - q: Can I export collection run results in XML format?
    a: |
      No. Currently, XML output isn't supported.
  - q: Can I configure which fields are redacted or shown in plaintext?
    a: |
      No. Insomnia uses predefined rules to determine which fields appear in plaintext and which are redacted. Keys remain visible in all modes.
  - q: Is the export format compatible with Postman’s collection run JSON?
    a: |
      Partially. The export format follows Postman’s JSON structure where it applies, but only includes fields relevant to Insomnia collections and executions.
  - q: Does the export feature support hashed or masked output modes?
    a: |
      No. The feature supports metadata-only, plaintext, and redacted modes only. Hashed or masked modes are not implemented.     
---

## Overview

This page provides reference information for exporting collection run results as JSON using the Inso CLI. It includes export modes, supported data formats, redaction behaviour, truncation limits, and the structure of the generated JSON output. Use this document as a companion to [export collection run results](/how-to/export-collection-run-results/).

## Export format and modes

Collection run results are exported in JSON format. The Inso CLI supports two export modes:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
rows:
  - mode: Metadata only
    description: "Exports identifiers, timings, status codes, and test results. Does not include headers, bodies, authentication fields, environment values, or proxy details."
  - mode: Full data
    description: "Exports the complete request information and the complete response information. Requires a full-data mode value and a risk-acceptance flag."
{% endtable %} 

### Metadata-only export

A metadata-only export includes collection identifiers, timestamps, response status codes, execution timings, and test results.

{:.info}
> Metadata-only doesn't include request headers, authentication data, request or response bodies, or any environment values.

### Full-data export

A full-data export includes:
- Request headers
- Authentication fields
- Query and path parameters
- Request bodies
- Response headers
- Response bodies
- Execution timings
- Environment data. 

Depending on your configuration, sensitive values appear either in plaintext or as redacted fields.

A full-data export requires:

- A full-data mode value: `--includeFullData=redact`
- A risk-acceptance flag: `--acceptRisk` 

{:.warning}
> If full-data mode is set without the risk-acceptance flag, the Inso CLI displays a security warning and doesn't write the output.

## Redaction behaviour

When `includeFullData=redact` is set, sensitive values are replaced with `<Redacted by Insomnia>` while their keys remain visible. Redaction applies to request data, response data, and environment variables. Redaction rules apply consistently across metadata sections, request objects, response objects, and environment objects.

Fields that are redacted:

- Cookies  
- Authorization headers  
- Authentication tokens  
- Bearer tokens  
- API keys  
- CSRF and XSRF tokens  
- Refresh tokens  
- Proxy-authorization values  

## Truncation limits

To prevent oversized output, the Inso CLI truncates large fields during full-data export.

- Default truncation limit: **4 KB** 
- Applies to request bodies and response bodies  
- Truncated values remain valid JSON  
- Truncation details appear in the output  

The truncation limit can be increased by specifying a custom maximum size in bytes.

## Output structure

The exported JSON file includes the following top-level structure:
```
{
  "timings": {},
  "stats": {},
  "collection": {},
  "environment": {},
  "executions": [{
    "request": {},
    "response": {},
    "tests": [],
  }],
  proxy: {},
  error: null
}
```

### Timings object

The `timings` object contains latency and duration metrics for the collection run. Example fields include:

- `responseAverage`  
- `responseMin`  
- `responseMax`  
- `started`  
- `completed`  

### Stats object

The `stats` object contains aggregated results. Example fields include:

- `iterations.total`  
- `iterations.failed`  
- `requests.total`  
- `requests.failed`  
- `tests.total`  
- `tests.failed`  

### Proxy object

The `proxy` object describes proxy settings inherited during the run. Example fields include:

- `proxyEnabled`  
- `httpProxy`  
- `httpsProxy`  
- `noProxy`  

### Collection object

The `collection` object contains identifiers and metadata for the collection executed. Fields include:

- `_id`  
- `type`  
- `parentId`  
- `name`  
- `description`  
- `created`  
- `modified`  
- `scope`  

### Environment object

Environment output varies by mode:
- Metadata-only mode includes identifiers only.  
- Redacted mode replaces values with `<Redacted by Insomnia>`.  
- Plaintext mode outputs complete environment values.

Keys and structure remain stable across all modes.

### Request objects

Request objects include URL, method, headers, authentication, scripts, and parameters. When using redaction, sensitive authentication values and sensitive request headers are replaced with `<Redacted by Insomnia>`.

An example of authentication fields that may be redacted:
- `token`  
- `password`  
- `clientSecret`  

Request headers that may be redacted include:

- `cookie`  
- `set-cookie`  
- `authorization`  
- `auth`  
- `x-auth-token`  
- `x-api-key`  
- `api-key`  
- `x-csrf-token`  
- `x-xsrf-token`  
- `x-access-token`  
- `x-refresh-token`  
- `bearer`  
- `basic`  
- `proxy-authorization`  

### Response objects

Response objects include response code, status, response time, headers, and body. Redacted mode replaces sensitive response headers and body values with `<Redacted by Insomnia>`.

Sensitive response headers include the same fields listed under request header redaction.

### Tests array

Each execution contains an array of test results. Tests include assertions and associated pass or fail statuses.

