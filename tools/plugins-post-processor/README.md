# plugins-post-processor

A collection of tools for processing Kong Gateway plugin JSON schemas.

## Tools

### 1. `run.js` - Schema Post-processor

Post-processes plugin JSON schemas to add documentation annotations for referenceable and encrypted fields.

#### How it works

The tool reads JSON schema files and recursively processes them to enhance field descriptions with documentation links:

1. **Referenceable fields**: Fields with the `x-referenceable` property get a link to the vault documentation added to their description.
2. **Encrypted fields**: Fields with the `x-encrypted` property get a link to the keyring documentation added to their description.
3. **Description handling**: If a field doesn't have a description, one is created. If it already has a description, the documentation link is appended.

The processed schemas are then written to the appropriate version directory under `app/_schemas/gateway/plugins/`.

### 2. `referenceable-fields.js` - Referenceable Fields Extractor

Extracts all referenceable fields from plugin schemas and generates a JSON file mapping plugins to their referenceable fields.

#### How referenceable-fields.js works

The tool reads processed plugin JSON schema files and:

1. **Recursively parses schemas**: Traverses the entire schema structure to find referenceable fields
2. **Detects referenceable fields**: Identifies fields that contain `[referenceable]` text in their descriptions or have the `x-referenceable` property
3. **Converts plugin names**: Automatically converts PascalCase filenames to kebab-case plugin names
4. **Generates output**: Creates a JSON file mapping each plugin to its referenceable field paths

The output is saved to `app/_data/plugins/referenceable_fields/<version>.json`.

## Installation

From the tool directory:

```bash
cd tools/plugins-post-processor
npm ci
```

## Usage

### Schema Post-processor (`run.js`)

Process plugin schemas to add documentation annotations for referenceable and encrypted fields.

#### Command formats

```bash
node run.js --schemas-path <path> --version <version>
```

#### Examples

```bash
node run.js --schemas-path ./input-schemas --version 3.12
```

#### Parameters

- `schemasPath`: Path to the directory containing input JSON schema files (relative to the script location)
- `version`: Gateway version string (e.g., "3.12", "3.11") - determines the output directory

#### Output

Processed schemas are written to: `app/_schemas/gateway/plugins/<version>/`

### Referenceable Fields Extractor (`referenceable-fields.js`)

Extract referenceable fields from processed plugin schemas and generate a mapping file.

#### Referenceable fields command formats

```bash
node referenceable-fields.js --version <version>
```

#### Referenceable fields examples

#### Referenceable fields parameters

- `version`: Gateway version string (e.g., "3.12", "3.11") - determines which schema directory to process

#### Referenceable fields output

Generated mapping file is saved to: `app/_data/plugins/referenceable_fields/<version>.json`

The output format is a JSON object where:

- Keys are plugin names in kebab-case (e.g., "aws-lambda", "openid-connect")
- Values are arrays of referenceable field paths (e.g., "config.client_secret", "config.redis.password")

## Technical Details

### Schema Post-processor

The script looks for these special properties in JSON schemas:

- `x-referenceable`: Adds text indicating the field can reference secrets stored in a vault
- `x-encrypted`: Adds text indicating the field is encrypted using the gateway keyring

The added documentation text includes markdown links to the relevant documentation sections.

### Referenceable Fields Extractor

The script identifies referenceable fields by:

- Looking for `[referenceable]` text in field descriptions (for processed schemas)
- Checking for the `x-referenceable` property (for unprocessed schemas)
- Converting PascalCase plugin filenames to kebab-case names programmatically
- Recursively traversing complex schema structures including nested objects and arrays
