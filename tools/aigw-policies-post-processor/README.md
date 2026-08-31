# aigw-policies-post-processor

A tool for post-processing Kong AI Gateway policy JSON schemas.

## How it works

The tool reads JSON schema files and recursively processes them, rewriting
the wording of every `description` field (at any nesting depth) from
Gateway-plugin terminology to AI Gateway policy terminology:

1. `plugins` → `policies`
2. `plugin` → `policy`

Matching is case-insensitive and case-preserving (e.g. `Plugin` → `Policy`,
`PLUGIN` → `POLICY`), and matches on word boundaries so it doesn't touch
substrings. The literal term `plugin-global` (used in Kafka/Confluent schema
registry descriptions) is left unchanged, since it's a fixed technical term
and not a reference to Gateway plugins.

Only `description` fields are rewritten; all other fields (`title`, `x-*`
metadata, etc.) are left untouched.

The processed schemas are written to `app/_schemas/ai-gateway/policies/`.

## Installation

From the tool directory:

```bash
cd tools/aigw-policies-post-processor
npm ci
```

## Usage

```bash
node run.js --schemas-path <path>
```

### Examples

```bash
node run.js --schemas-path ./input-schemas
node run.js -s ./input-schemas
```

### Parameters

- `schemasPath`: Path to the directory containing input JSON schema files
  (relative to the script location)

### Output

Processed schemas are written to: `app/_schemas/ai-gateway/policies/`
