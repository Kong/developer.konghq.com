---
title: "Patching tagged configuration files with kongctl"
description: "Edit tagged YAML without resolving its values."
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Declarative configuration overview
    url: /kongctl/declarative/
  - text: Supported resources
    url: /kongctl/supported-resources/
---

Read this page when editing YAML with `kongctl patch file` while retaining
custom tags.

## Patching tagged configuration

`kongctl patch file` preserves custom tags in the input when writing YAML,
including `!ref`, `!file`, `!env`, `!secret`, `!lookup`, and `!external`.
Patching does not resolve references, read tagged files, evaluate environment
variables, or fetch secrets. Tags survive even when no selector matches or the
patch makes no changes.

Updating a child of a tagged mapping preserves the mapping's tag and any
untouched child tags. Setting a field replaces its entire value, including its
old tag; replacement objects are not recursively merged. Appending to a tagged
sequence preserves its tag and existing entries. Inline values and patch-file
values use JSON-compatible types; introducing custom tags through patch values
is unsupported.

`--format json` fails if custom tags remain after patching, because JSON cannot
represent them. Use YAML output, or explicitly remove or replace the tagged
fields before requesting JSON output. Failed serialization does not overwrite
the output file.

Input must contain a single mapping document. Additional YAML documents,
including an empty document introduced by a trailing `---`, are rejected instead
of silently discarded. YAML output also fails before writing if a patch removes
or replaces an anchor that a remaining alias still needs.

Tag preservation is a semantic guarantee. Comments, key ordering, anchors, and
byte-for-byte formatting are not guaranteed to remain unchanged.
