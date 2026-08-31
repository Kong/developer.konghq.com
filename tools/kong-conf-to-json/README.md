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

### The `--set-min-version` argument

`--set-min-version` writes the same `min_version` on **every** param in `index.json`. It replaces the values that the version comparison found.

Use it only to bootstrap a product that has one single version file. In that case the comparison cannot run, so no param gets a `min_version`, and the reference page shows no version information.

`ai-gateway` was in this condition for its first release:

```bash
node run --file=../../../kong-ee/kong.conf.default --version=2.0 --product=ai-gateway
node index-file --product=ai-gateway --set-min-version=2.0
```

All the params in `app/_kong-conf/ai-gateway/index.json` then have `min_version: { "ai-gateway": "2.0" }`.

Do not use `--set-min-version` when the product has more than one version file. It would overwrite the correct per-param values with one single version.

### How to add a new version

1. Check out the `kong-ee` branch or tag of the new release.
2. Parse the `kong.conf` file for the new version, e.g. for AI Gateway 2.1:

   ```bash
   node run --file=../../../kong-ee/kong.conf.default --version=2.1 --product=ai-gateway
   ```

3. Generate the index file again, without `--set-min-version`:

   ```bash
   node index-file --product=ai-gateway
   ```

4. Check the diff on `index.json`. The params that 2.1 adds must have `min_version: { "ai-gateway": "2.1" }`, and the params that 2.1 removes must have `removed_in: { "ai-gateway": "2.1" }`.

Step 3 also removes the `min_version` keys that `--set-min-version=2.0` wrote on the baseline params, because 2.0 is now the oldest version file. This agrees with the behavior of the `gateway` product, where the oldest version is the implicit baseline.

## Where the data is used

- `app/_plugins/drops/kong_conf.rb` reads `app/_kong-conf/<product>/index.json`.
- `app/_plugins/tags/kong_conf.rb` selects the product from the first value of the page `products` field.
- `{% kong_conf %}` renders the reference page, e.g. `app/gateway/configuration.md` and `app/ai-gateway/configuration.md`.

## Automation

The `.github/workflows/generate-kong-conf-json.yml` workflow runs both commands with the default product, so it supports `gateway` only. Run the commands locally for `ai-gateway`.
