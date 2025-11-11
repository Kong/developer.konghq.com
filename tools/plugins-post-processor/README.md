# plugins-post-processor

Post-process plugin JSON schemas to add documentation annotations for referenceable and encrypted fields.

## How it works

The tool reads JSON schema files and recursively processes them to enhance field descriptions with documentation links:

1. **Referenceable fields**: Fields with the `x-referenceable` property get a link to the vault documentation added to their description.
2. **Encrypted fields**: Fields with the `x-encrypted` property get a link to the keyring documentation added to their description.
3. **Description handling**: If a field doesn't have a description, one is created. If it already has a description, the documentation link is appended.

The processed schemas are then written to the appropriate version directory under `app/_schemas/gateway/plugins/`.

## How to run it

### Install dependencies

From the tool directory:

```bash
cd tools/plugins-post-processor
npm ci
```

### Running the script

The script accepts input schemas and processes them for a specific Gateway version. It supports multiple argument formats:


#### Named arguments

```bash
node run.js --schemas-path <path> --version <version>
```

Example:

```bash
node run.js --schemas-path ./input-schemas --version 3.12
```

### Parameters

- `schemasPath`: Path to the directory containing input JSON schema files (relative to the script location)
- `version`: Gateway version string (e.g., "3.12", "3.11") - determines the output directory

### Output

Processed schemas are written to: `app/_schemas/gateway/plugins/<version>/`

The script will:

- Create the output directory if it doesn't exist
- Process all `.json` files in the input directory
- Display progress information for each processed file
- Report any errors encountered during processing

## Schema Processing Details

The script looks for these special properties in JSON schemas:

- `x-referenceable`: Adds text indicating the field can reference secrets stored in a vault
- `x-encrypted`: Adds text indicating the field is encrypted using the gateway keyring

The added documentation text includes markdown links to the relevant documentation sections.
