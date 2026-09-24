# mesh-policy-examples-validator

Validates the published Kong Mesh policy example config blocks against the vendored
Kuma CRD schemas.

## How it works

1. Resolves one vendored CRD directory per mesh major present in the build: the
   release marked `latest: true` in `app/_data/products/mesh.yml` for the
   unversioned pages, and the biggest 2.x release for the `/mesh/v2/` pages,
   at `app/assets/mesh/<number>.x/raw/crds`.
1. Indexes every CRD by its declared `spec.names.kind`, and hardens each schema by
   adding `additionalProperties: false` to every object that declares `properties`,
   skipping any node carrying `x-kubernetes-preserve-unknown-fields`.
1. Globs the built pages at `dist/mesh/policies/*/examples/*/index.html` and
   `dist/mesh/v2/policies/*/examples/*/index.html`, and the source examples at
   `app/_mesh_policies/*/examples/*.{yaml,yml}` and
   `app/_mesh_policies/v2/*/examples/*.{yaml,yml}`, and fails loudly if the built
   page count doesn't match the source example count.
1. For each built page, extracts the published config blocks from
   `div[data-tab-group^="policy-yaml"] div[data-panel] code[id]`, keeping the
   `kubernetes` and `universal` panels, and the `terraform` panel as raw text.
   A terraform block is not YAML: it never reaches the YAML parse, schema,
   empty-value, or marker rules.
1. Applies three rules to each YAML block, and reports findings as the source path
   (`app/_mesh_policies/<policy>/examples/<name>.yaml`), the panel, and a JSON
   pointer:
    - **Schema**: validates a `kubernetes` block as a whole manifest against the
      hardened CRD schema, and a `universal` block's `spec` against the hardened
      `properties.spec`.
    - **No null values**: no published key may hold a null value.
    - **No surviving marker fields**: no internal renderer marker key (`_*`,
      `name_uni`, `name_kube`) may survive into the published output.
1. Checks every terraform block for HCL grammar: the block is written to a temp
   `.tf` file and `terraform fmt` (write mode) runs on it. The rewritten file is
   discarded, so style never matters; a non-zero exit is a gating finding naming
   the source example. This rule runs on every run.
1. Prints a summary giving the number of pages checked, blocks checked, blocks with
   meaningful schema coverage, terraform blocks checked, and the finding count.

## The `--skip` flag

Pass `--skip <policy1,policy2,...>` to exclude one or more policy folders (the
directory name under `app/_mesh_policies/`) from a run, for example while a policy's
examples are under active rewrite:

```bash
node index.js --skip external-services,mesh-rate-limit
```

A plain policy name applies to every major. To exclude the policy in one major
only, qualify the name with the major: `--skip external-services@v2` skips the
`/mesh/v2/` pages and the `app/_mesh_policies/v2/` source tree, while the same
policy in the latest tree is still checked (`--skip external-services@v3` does
the reverse).

The listed policies are filtered out of both the built-page and source-example globs
before the build-precondition check runs, so a skipped policy's missing or mismatched
build output no longer fails the run. Every other policy is still checked. The run
summary always names the requested skip list, so a skip (or a typo'd, unmatched
policy name) stays visible in the output.

## Requires a production build

The validator reads `dist/`, not the Markdown source. `jekyll-dev.yml` skips the
mesh policy and markdown page generators in a dev build, so a dev build produces
nothing to validate. Run `make build` first, or comment out the `skip:` section in
`jekyll-dev.yml`.

## Requires the terraform binary

The terraform grammar rule shells out to `terraform`. Install terraform
(https://developer.hashicorp.com/terraform/downloads) and make sure `terraform`
is on PATH. The binary is only needed to check terraform blocks; pages without a
terraform panel validate without it. Tests that exercise the grammar rule spawn
the real binary; the tests never contact a registry.

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
