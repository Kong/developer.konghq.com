# sandbox-allowlist

Generates the data files in `app/_data/sandbox_allowlist/` from the Lua sandbox allowlists in the `kong-ee` source. The Lua sandboxing pages render their tables from those files, so nobody has to maintain the lists by hand.

| Product | Data file | Page |
|---------|-----------|------|
| `gateway` | `app/_data/sandbox_allowlist/gateway.yml` | `app/gateway/sandboxing.md` |
| `ai-gateway` | `app/_data/sandbox_allowlist/ai-gateway.yml` | `app/ai-gateway/sandboxing.md` |

## Usage

1. In your `kong-ee` clone, check out the release or branch you want to document. For Kong Gateway, use a release tag such as `3.16.0.0`. For AI Gateway, use an AI Gateway branch such as `aigw-master`.

2. From the root of this repository, run the script with the path to `kong-ee`, the product, and optionally a version (not required for AI Gateway):

   ```sh
   node tools/sandbox-allowlist/extract.js --path /path/to/kong-ee --product [gateway|ai-gateway] [--version 3.16]
   ```

3. Review the diff of the data file and commit it.

| Argument | Required | Description |
|----------|----------|-------------|
| `--path` | Yes | Path to your local `kong-ee` clone. |
| `--product` | Yes | `gateway` or `ai-gateway`. |
| `--version` | No | The release to record, for example `3.16`. Kong Gateway only. |

### Kong Gateway

The script reads the release number (for example `3.16`) from `meta.lua` in the checkout. If that number is wrong for the branch you're on, set it yourself:

```sh
node tools/sandbox-allowlist/extract.js --path /path/to/kong-ee --product gateway --version 3.16
```

The release must be listed in `app/_data/products/gateway.yml`.

### AI Gateway

AI Gateway has no versions in the data file, only the latest. Check out the AI Gateway branch and run the script without `--version`:

```sh
git -C /path/to/kong-ee checkout aigw-master
node tools/sandbox-allowlist/extract.js --path /path/to/kong-ee --product ai-gateway
```

The script rewrites the whole data file on every run, and the file has no `min_version` or `max_version` fields.

The script needs the `yaml` package. Run `npm install` in this directory if it's missing.

## What it reads

All files are under `kong/tools/sandbox/` in `kong-ee`:

| File | Used for |
|------|----------|
| `environment/{lua,strict,lax}.lua` | Functions and constants available in each mode |
| `environment/init.lua` | `kong.log.*` and `ngx.*` fields, which are defined in code instead of in the lists |
| `require/{lua,strict,lax}.lua` | Modules that `require` allows in each mode |

## How versions are tracked (Kong Gateway)

The `gateway` data file doesn't hold a copy of the lists for every release. Each name can carry two optional fields, the same ones the rest of the docs tooling uses:

| Field | Meaning |
|-------|---------|
| `min_version` | The first release the name was available in. The page shows a `v3.15+` badge. |
| `max_version` | The last release the name was available in (inclusive). The page keeps the name and shows an `up to v3.14` badge. With both fields, the badge reads `v3.14 to v3.16`. |

A name with neither field has been available since tracking began, and the page shows no version for it.

Each run compares the source to the data file:

- A name that is new gets `min_version` set to this release.
- A name that is gone gets `max_version` set to the previous release.
- A name that comes back loses its `max_version`.

Running the same release twice changes nothing. A name that moves between modes shows up as one removal and one addition. For example, `kong.router.get_route` moved from lax to strict in 3.15.

Run the script for each release in order, oldest first. Running an older release after a newer one gives wrong labels.

## Data file format

The file is a list of four blocks. `kind` is `environment` or `require`, and `mode` is `strict` or `lax`. The `lax` blocks list only what lax mode adds on top of strict mode.

```yaml
- kind: environment
  mode: strict
  groups:
    - id: kong.metrics
      names:
        - name: kong.metrics.counter
          min_version: "3.16"
```

Groups are the parent table of each name (`math.abs` goes in `math`, `kong.request.get_path` goes in `kong.request`). Nothing is labeled by hand, so a new library appears under its own id without any change to the script.

## When the script fails

The script stops with an error instead of writing wrong data in these cases:

- **The inheritance chain changed.** The script expects `lax` to extend `strict`, and `strict` to extend `lua`. If Kong restructures the files, update the script.
- **A name is in both strict and lax.** The `lax` lists must only hold additions.
- **The `kong.log` or `ngx` field lists can't be found.** Releases up to 3.14 define them inline, and 3.15 and later use `KONG_LOG_ALLOWLIST` and `NGX_ALLOWLIST`. If the code changes again, update `specialNames()` in the script.
