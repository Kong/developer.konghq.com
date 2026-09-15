# mesh-policy-examples-validator

Validates the published Kong Mesh policy example config blocks against the vendored
Kuma CRD schemas.

## How it works

1. Resolves the CRD directory from the release marked `latest: true` in
   `app/_data/products/mesh.yml` (or the release passed via `--version`), at
   `app/assets/mesh/<number>.x/raw/crds`.
1. Indexes every CRD by its declared `spec.names.kind`, and hardens each schema by
   adding `additionalProperties: false` to every object that declares `properties`,
   skipping any node carrying `x-kubernetes-preserve-unknown-fields`.
1. Globs the built pages at `dist/mesh/policies/*/examples/*/index.html` and the
   source examples at `app/_mesh_policies/*/examples/*.{yaml,yml}`, and fails loudly
   if the built page count doesn't match the source example count.
1. For each built page, extracts the published config blocks from
   `div[data-tab-group^="policy-yaml"] div[data-panel] code[id]`, keeping the
   `kubernetes` and `universal` panels and skipping `terraform`.
1. Applies three rules to each block, and reports findings as the source path
   (`app/_mesh_policies/<policy>/examples/<name>.yaml`), the panel, and a JSON
   pointer:
   - **Schema**: validates a `kubernetes` block as a whole manifest against the
     hardened CRD schema, and a `universal` block's `spec` against the hardened
     `properties.spec`.
   - **No null values**: no published key may hold a null value.
   - **No surviving marker fields**: no internal renderer marker key (`_*`,
     `name_uni`, `name_kube`) may survive into the published output.
1. Prints a summary giving the number of pages checked, blocks checked, blocks with
   meaningful schema coverage, and the finding count.

## The `--version` flag

By default the validator resolves the CRD directory from the release marked
`latest: true` in `app/_data/products/mesh.yml`. Pass `--version <number>` to
validate against a different vendored release, for example while a CRD refresh is
pending:

```bash
node index.js --version 2.13
```

## Requires a production build

The validator reads `dist/`, not the Markdown source. `jekyll-dev.yml` skips the
mesh policy and markdown page generators in a dev build, so a dev build produces
nothing to validate. Run `make build` first, or comment out the `skip:` section in
`jekyll-dev.yml`.

## Caveat: permissive schemas pass quietly

29 of the 60 vendored kinds, including `ExternalService` and every legacy resource,
declare `x-kubernetes-preserve-unknown-fields: true` at their specification root. The
CRD schema accepts anything for these, so the schema rule passes quietly for them.
The null-value and marker-field rules still apply. The summary line reports how many
blocks received meaningful schema coverage, so the gap stays visible without being
fatal.

## How to run it

From the tool directory:

```bash
cd tools/mesh-policy-examples-validator
npm install
node index.js
```

## How to run the tests

```bash
npm test --prefix tools/mesh-policy-examples-validator
```
