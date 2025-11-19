---
title: Export collection run results to JSON
content_type: reference
layout: reference
description: Learn how the Inso CLI exports Insomnia collection run results as JSON, including metadata-only mode, full-data export, redaction, truncation, and JSON structure.

products:
  - insomnia

tools:
  - inso-cli

related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Inso CLI overview
    url: /inso-cli/
  - text: Inso CLI configuration
    url: /inso-cli/configuration/
---

The Inso CLI exports JSON reports for Insomnia collection runs. JSON output follows a Postman-style structure and supports metadata-only and full-data export modes. Redaction and truncation ensure that sensitive information is protected.

Run the following command to export:

```sh
inso run collection <collection name> --env <environment> --output <file>
```

## Export modes

The Inso CLI supports the following export modes:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
rows:
  - mode: Metadata only
    description: "Exports identifiers, timings, status codes, and test results. Doesn't include headers, bodies, authentication fields, or environment data."
  - mode: Full data
    description: "Exports complete request and response information. Requires the `includeFullData` mode flag and an explicit acceptance flag for security."
{% endtable %}

### Metadata-only export

Metadata reports include:

- Request identifiers  
- Timestamps  
- Response status codes  
- Execution timings  
- Test results  
Example:

```
inso run collection "My Collection" \
  --env "Base Environment" \
  --output results.json
```

### Full data export

A full data export includes:

- Request headers  
- Authentication fields  
- Query parameters and request bodies  
- Response headers  
- Response bodies  
- Execution timings  
- Environment data (redacted or plaintext depending on mode)  

To prevent accidental exposure of secure credentials, full export requires:

1. A data-exposure mode  
2. Explicit risk acceptance  

## Supported includeFullData values

{% table %}
columns:
  - title: Value
    key: value
  - title: Behaviour
    key: behaviour
rows:
  - value: redact
    behaviour: "Exports all fields but replaces sensitive values with `<Redacted by Insomnia>`."
  - value: plaintext
    behaviour: "Exports every field exactly as stored. Sensitive information is not redacted."
{% endtable %}

### Example: redact mode

```sh
inso run collection "My Collection" \
  --env "Base Environment" \
  --includeFullData=redact \
  --acceptRisk \
  --output results.json
```

### Example: plaintext mode

```sh
inso run collection "My Collection" \
  --env "Base Environment" \
  --includeFullData=plaintext \
  --acceptRisk \
  --output results.json
```

## Risk warning

If a full-data mode is set without `--acceptRisk`, Inso interrupts the operation and displays:

```
SECURITY WARNING
The output file may contain sensitive data like API tokens. Exposing this file is a security risk.
To continue, run again with --acceptRisk.
```

## Redaction behaviour

When using `includeFullData=redact`, Insomnia preserves keys but replaces sensitive values with:

```
<Redacted by Insomnia>
```

Sensitive fields include:

- cookies  
- authorization headers  
- bearer tokens  
- API keys  
- CSRF and XSRF tokens  
- refresh tokens  
- proxy authorization values  

Redaction applies to request fields, response fields, and environment variables.

## Truncation rules

To prevent oversized output, Inso truncates large fields.

- Default limit: **4 KB**
- Applies to request and response bodies
- Truncated fields remain valid JSON and indicate truncation

Override the limit with `--maxDataSize` (bytes):

```sh
inso run collection "My Collection" \
  --env "Base Environment" \
  --includeFullData=redact \
  --acceptRisk \
  --maxDataSize 16384 \
  --output results.json
```

## JSON structure

Exported run results follow this structure:

```
{
  "timings": {},
  "stats": {},
  "collection": {},
  "environment": {},
  "executions": [
    {
      "request": {},
      "response": {},
      "tests": []
    }
  ],
  "proxy": {},
  "error": null
}
```

## Validate exported results

Confirm the generated results file contains:

1. A `collection` object with metadata  
2. An `environment` section (redacted or plaintext)  
3. A populated `executions` array  
4. Redacted values marked as `<Redacted by Insomnia>`  
5. Truncated fields where expected  
6. Full request and response data only when includeFullData is set  
