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
Use the Inso CLI to export collection run results as a JSON file. The CLI supports two output modes:
- **Metadata-only** (default)
- **Full data**, with optional redaction and truncation controls

## Export collection run results (metadata only)

Run the following command to export collection run metadata that contains identifiers, timings, and test results:

```
./inso run collection "Flights 0.1.0" --env "Base Environment" --output file.json
```

### Export full data

If you require all of the information associated with a collection run, perform a full-data export. Full-data exports include request headers, authentication fields, parameters, request bodies, response headers, response bodies, timings, and environment values. Sensitive fields appear in plaintext or as redacted values, depending on the mode selected.

To include full request and response data with redaction activated, activate full-data mode and accept the security risk:
```
./inso run collection "Flights 0.1.0" --env "Base Environment" --output file.json --includeFullData=redact --acceptRisk
```
For detailed information about export modes, redaction rules, truncation limits, and the JSON structure, go to the [Collection run results export](/insomnia/collection-run-results-export/) reference article.