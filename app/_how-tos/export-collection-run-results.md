---
title: Export collection run results to JSON

content_type: how_to

description: Learn how the Inso CLI exports Insomnia collection run results as JSON, including metadata-only mode, full-data export, redaction, truncation, and JSON structure.

products:
  - insomnia

tools:
  - inso-cli

tldr:
  q: How do I export collection run results as JSON?
  a: Run `inso run collection "collection name" --env "environment name" --output results.json` to export run metadata. To export full request and response data, add `--verbose` and `--include_full_data`.

prereqs:
    inline:
        - title: Create and configure a collection
          include_content: prereqs/create-collection
          icon_url: /assets/icons/menu.svg 

related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Inso CLI overview
    url: /inso-cli/
  - text: Inso CLI configuration
    url: /inso-cli/configuration/
---
Use the Inso CLI to export collection run results as a JSON file. Output supports two modes:
- Metadata only
- Full data with optional redaction

## Export collection run results

Run the following command to export a results file:

```sh
inso run collection <collection name> --env <environment> --output <file>
```

### Export modes

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

### Export metadata only

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

### Export full request and response data

A full data export includes:

- Request headers  
- Authentication fields  
- Query parameters and request bodies  
- Response headers  
- Response bodies  
- Execution timings  
- Environment data (redacted or plaintext depending on mode)  

To prevent accidental exposure of secure credentials, full export requires:

1. A full-data mode value  
2. An explicit risk-acceptance flag

If a full-data mode is set without `--acceptRisk`, Inso CLI interrupts the operation and displays:

```
SECURITY WARNING
The output file may contain sensitive data like API tokens. Exposing this file is a security risk.
To continue, run again with --acceptRisk.
```

## Choose a full-data mode
Use `includeFullData` to set the exposure mode:

{% table %}
columns:
  - title: Value
    key: value
  - title: Behaviour
    key: behaviour
rows:
  - value: redact
    behaviour: |
      Exports all fields but replaces sensitive values with `<Redacted by Insomnia>`. For example:
      ```sh
      inso run collection "My Collection" \
      --env "Base Environment" \
      --includeFullData=redact \
      --acceptRisk \
      --output results.json
      ``` 
  - value: plaintext
    behaviour: |
      Exports every field exactly as stored. Sensitive information is included in full. For example:
      ```sh
      inso run collection "My Collection" \
      --env "Base Environment" \
      --includeFullData=plaintext \
      --acceptRisk \
      --output results.json
      ```
{% endtable %}

## Review redaction behaviour

When using `includeFullData=redact`, Insomnia Insomnia keeps keys visible and replaces sensitive values with:

```
<Redacted by Insomnia>
```

Sensitive fields include:

- Cookies  
- Authorization headers  
- Bearer tokens  
- API keys  
- CSRF and XSRF tokens  
- Refresh tokens  
- Proxy authorization values  

Redaction applies to request fields, response fields, and environment variables.

## Adjust truncation limits

To prevent oversized output, Inso CLI truncates large fields.

- Default limit: **4 KB**
- Applies to bodies in requests and responses
- Truncated fields remain valid JSON and indicate truncation

Increase the limit with `--maxDataSize` (bytes):

```sh
inso run collection "My Collection" \
  --env "Base Environment" \
  --includeFullData=redact \
  --acceptRisk \
  --maxDataSize 16384 \
  --output results.json
```

## Validate exported results

Confirm that the generated results file contains:

1. A `collection` object with metadata  
2. An `environment` section (redacted or plaintext)  
3. A populated `executions` array  
4. Redacted values marked as `<Redacted by Insomnia>`  
5. Truncated fields where expected  
6. Full request and response data only when includeFullData is set

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
