# changelog-generator

Generate changelogs for Gateway and AI Gateway based on entries defined in their respective repos.

Supported products: `gateway` (default), `ai-gateway`.

## How it works

There are three stages to the process:

1. Generate YAML entry files from the product's Markdown changelog (`md-to-yml.js`).
2. Merge those YAML files into a per-version JSON temp file (`run.js`).
3. Merge the temp files into the final changelog JSON (`changelog.js`).

## How to run it

Requires the `kong-ee` repo to be available locally.
From the root of your clone of the dev site repo, install dependencies:

```bash
cd tools/changelog-generator
npm ci
```

Make sure that the `./tmp` folder is empty before you run any of the commands.

## Gateway

### 1. Generate yml entries from the changelog file

```bash
node md-to-yml.js --path='../../../kong-ee' --version='3.10.0.2'
# or explicitly:
node md-to-yml.js --path='../../../kong-ee' --version='3.10.0.2' --product=gateway
```

Reads `<kong-ee>/changelog/3.10.0.2/3.10.0.2.md`, writes YAML files to `./tmp/gateway/changelog/3.10.0.2/<component>/`.

### 2. Generate temp files for specific versions

```bash
node run.js --path='./tmp/gateway' --version='3.10.0.2'
# or explicitly:
node run.js --path='./tmp/gateway' --version='3.10.0.2' --product=gateway
```

Creates `./tmp/gateway/3.10.0.2.json`. Omit `--version` to process all versions found under `./tmp/gateway/changelog/`.

### 3. Set the release date

Open `app/_data/products/gateway.yml` and add a new entry in `release_dates`:

```yaml
release_dates:
  '3.10.0.2': 2025/05/20
```

### 4. Generate/update the changelog

```bash
node changelog.js
# or explicitly:
node changelog.js --product=gateway
```

Reads `./tmp/gateway/*`, `./missing_changelogs/*`, and `./missing_entries/`, writes to `app/_changelogs/gateway.json`.

- `missing_changelogs`: changelog files for versions that predate the YAML-entry process.
- `missing_entries`: manual entries (e.g. known issues) not present in `kong-ee`.

### Full flow for a new Gateway release

1. Make sure your local `kong-ee` is up to date and on the right branch.
1. `node md-to-yml.js --path='../../../kong-ee' --version='<version>'`
1. `node run.js --path='./tmp/gateway' --version='<version>'`
1. Update `app/_data/products/gateway.yml` with the new version and release date.
1. `node changelog.js`


## AI Gateway

### 1. Generate yml entries from the changelog file

```bash
node md-to-yml.js --path='../../../ai-gateway' --version='1.2.3' --product=ai-gateway
```

Reads `<ai-gateway>/changelog/aigw-1.2.3/aigw-1.2.3.md`, writes YAML files to `./tmp/ai-gateway/changelog/1.2.3/<component>/`.

### 2. Generate temp files for specific versions

```bash
node run.js --path='./tmp/ai-gateway' --version='1.2.3' --product=ai-gateway
```

Creates `./tmp/ai-gateway/1.2.3.json`. Omit `--version` to process all versions found under `./tmp/ai-gateway/changelog/`.

### 3. Set the release date

Open `app/_data/products/ai-gateway.yml` and add a new entry in `release_dates`:

```yaml
release_dates:
  '1.2.3': 2025/05/20
```

### 4. Generate/update the changelog

```bash
node changelog.js --product=ai-gateway
```

Reads `./tmp/ai-gateway/*`, writes to `app/_changelogs/ai-gateway.json`.

### Full flow for a new AI Gateway release

1. Make sure your local `ai-gateway` repo is up to date and on the right branch.
1. `node md-to-yml.js --path='../../../ai-gateway' --version='<version>' --product=ai-gateway`
1. `node run.js --path='./tmp/ai-gateway' --version='<version>' --product=ai-gateway`
1. Update `app/_data/products/ai-gateway.yml` with the new version and release date.
1. `node changelog.js --product=ai-gateway`
