# kong-conf-to-json

Parse kong.conf and stores a json representation in `app/_kong-conf/<product>/<version>.json`.
Generate a json representation of kong.conf in `app/_kong-conf/<product>/index.json` with the version information of each field.

Supported products: `gateway` (default), `ai-gateway`.

## How it works

`kong-conf-to-json` requires `kong/kong-ee` to be available locally.
From the root of your clone of the dev site repo:

```bash
cd tools/kong-conf-to-json
npm ci
```

## How to run it

Transform a `kong.conf` file to `json` format by passing the relative path to the `kong.conf` file and its `version`, e.g.

`node run --file=../../../kong-ee/kong.conf.default --version=3.9  --product=gateway`

will parse the file and write it to `app/_kong-conf/gateway/3.9.json`.

For `ai-gateway`, check out the `kong-ee` branch or tag of the matching AI Gateway release, then pass the AI Gateway version:

`node run --file=../../../kong-ee/kong.conf.default --version=2.0 --product=ai-gateway`

will write the file to `app/_kong-conf/ai-gateway/2.0.json`.

The `--product` argument only selects the output directory. The parser is the same for all products.

### Index file generation

After generating the fields for each version in the previous step, the `index.json` file can be generated.

`node index-file --product=gateway`

will generate a json file containing the version information for each param and store it in `app/_kong-conf/gateway/index.json`.

The command compares each version file with the version file before it, and adds these keys to `index.json`:

- `min_version: { "<product>": "<version>" }` for each param that the version adds.
- `removed_in: { "<product>": "<version>" }` for each param that the version removes.

The oldest version file is the baseline. Its params get no `min_version` key, because the tool has no earlier version to compare them to.

### The `--baseline-min-version` argument

`--baseline-min-version=<version>` writes `min_version` only on the params that the version comparison did not stamp, that is, the params of the baseline (oldest) version file. It does not touch the `min_version` values that the comparison found, so params added in later versions keep their own version.

Use it when the product must show a "Min Version" badge on its baseline params. For `ai-gateway`, 2.0 is the first release of the product, so the reference page must show `min_version: { "ai-gateway": "2.0" }` on the 2.0 params, while params that 2.1 adds keep `min_version: { "ai-gateway": "2.1" }`:

```bash
node run --file=../../../kong-ee/kong.conf.default --version=2.0 --product=ai-gateway
node index-file --product=ai-gateway --baseline-min-version=2.0
```

When the product has one single version file, every param is a baseline param, so `--baseline-min-version` stamps all of them. It is safe to run on every regeneration, including after a new version file is added: the new version's params still get their own `min_version` from the comparison.

### How to add a new version

1. Check out the `kong-ee` branch or tag of the new release.
2. Parse the `kong.conf` file for the new version, e.g. for AI Gateway 2.1:

   ```bash
   node run --file=../../../kong-ee/kong.conf.default --version=2.1 --product=ai-gateway
   ```

3. Generate the index file again. For `ai-gateway`, pass `--baseline-min-version=2.0`; for `gateway`, run it without an extra flag:

   ```bash
   node index-file --product=ai-gateway --baseline-min-version=2.0
   ```

4. Check the diff on `index.json`. The params that 2.1 adds must have `min_version: { "ai-gateway": "2.1" }`, the params that 2.1 removes must have `removed_in: { "ai-gateway": "2.1" }`, and the baseline 2.0 params must keep `min_version: { "ai-gateway": "2.0" }`.

For the `gateway` product, the oldest version is the implicit baseline: its params get no `min_version`, and regenerating the index after a new version file keeps that behavior.

## Where the data is used

- `app/_plugins/drops/kong_conf.rb` reads `app/_kong-conf/<product>/index.json`.
- `app/_plugins/tags/kong_conf.rb` selects the product from the first value of the page `products` field.
- `{% kong_conf %}` renders the reference page, e.g. `app/gateway/configuration.md` and `app/ai-gateway/configuration.md`.

## Automation

- `.github/workflows/generate-kong-conf-json.yml` runs both commands with the default product, so it supports `gateway` only.
- `.github/workflows/generate-aigw-kong-conf-json.yml` runs both commands with `--product=ai-gateway --baseline-min-version=2.0`.
