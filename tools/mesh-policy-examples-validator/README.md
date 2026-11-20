# mesh-policy-examples-validator

Validates every published Kong Mesh policy config block against the vendored
Kuma CRD schemas: the policy example pages, the policy overview pages, and the
other mesh pages that publish `{% policy_yaml %}` tabs.

## How it works

1. Resolves one vendored CRD directory per mesh major present in the build: the
   release marked `latest: true` in `app/_data/products/mesh.yml` for the
   unversioned pages, and the biggest 2.x release for the `/mesh/v2/` pages,
   at `app/assets/mesh/<number>.x/raw/crds`.
1. Indexes every CRD by its declared `spec.names.kind`, and hardens each schema by
   adding `additionalProperties: false` to every object that declares `properties`,
   skipping any node carrying `x-kubernetes-preserve-unknown-fields`.
1. Discovers three classes of pages, each mapped from its source to its built
   page, and checks each class in its own phase:

   | Class | Source | Built page |
   |-------|--------|------------|
   | Policy example pages | `app/_mesh_policies/(v2/)?<policy>/examples/*.yaml` (built-driven, as before) | `dist/mesh/(v2/)?policies/<policy>/examples/<name>/index.html` |
   | Policy overview pages | `app/_mesh_policies/(v2/)?<policy>/index.md` containing `{% policy_yaml %}` | `dist/mesh/(v2/)?policies/<policy>/index.html` |
   | Other mesh pages | `app/mesh/(v2/)?<slug>.md` containing `{% policy_yaml %}` | `dist/mesh/(v2/)?<slug>/index.html` |

   Discovery for the two new classes is source-driven: a built page parked under
   the policies URL space with no source (for example `mutual-tls`) is never
   checked. The validator fails loudly if any checked source page has no built
   page.
1. For each built page, extracts the published config blocks from
   `div[data-tab-group^="policy-yaml"] div[data-panel] code[id]`, keeping the
   `kubernetes` and `universal` panels, and the `terraform` panel as raw text.
   A terraform block is not YAML: it never reaches the YAML parse, schema,
   empty-value, or marker rules. A page may publish several `{% policy_yaml %}`
   instances; each block records the ordinal of its instance in document order,
   and a finding on a multi-instance page names it, for example
   `app/mesh/v2/hostnamegenerator.md [kubernetes, block 3]`.
1. Applies three rules to each YAML block, and reports findings as the source path,
   the panel (with the instance ordinal on multi-instance pages), and a JSON
   pointer:
     - **Schema**: validates a `kubernetes` block as a whole manifest against the
       hardened CRD schema, and a `universal` block's `spec` against the hardened
       `properties.spec`.
     - **No null values**: no published key may hold a null value.
     - **No surviving marker fields**: no internal renderer marker key (`_*`,
       `name_uni`, `name_kube`) may survive into the published output.
1. Checks the instance count of every overview and other mesh page: the number of
   `policy-yaml` tab groups in the built page must equal the number of
   `{% policy_yaml %}` instances in the source file. A mismatch is a gating
   finding naming both counts; the run continues and checks every other page.
1. Checks every terraform block for HCL grammar: the block is written to a temp
   `.tf` file and `terraform fmt` (write mode) runs on it. The rewritten file is
   discarded, so style never matters; a non-zero exit is a gating finding naming
   the source page. This rule runs on every run and is not affected by the
   `--terraform-validate` mode flag. The three page classes publish 218
   terraform blocks in total (129 example, 58 overview, 31 other).
1. Checks every terraform block against the schema of the pinned Konnect
    Terraform provider (`kong/konnect-beta`), controlled by
    `--terraform-validate=off|warn|gate` (default `gate`): the block is wrapped
    in a per-block harness that declares the provider, an empty
    `provider "konnect-beta" {}` block (validate never contacts Konnect and needs
    no token), and stub `konnect_mesh` and `konnect_mesh_control_plane` resources
    for the mesh references the published blocks carry. `terraform init` and
    `terraform validate` run in that harness directory. All harness directories
    share a `TF_PLUGIN_CACHE_DIR`, so the provider downloads once per run. In
    `gate` mode a finding is gating: it is printed, counted, and makes the run
    exit non-zero. In `warn` mode it is advisory: printed and counted, but it
    does not affect the exit status. `off` skips the check.
1. Prints a phase label per page class, with the three progress lines under it
   (Kubernetes and Universal blocks, terraform grammar, provider schema). A step
   that does not run (`off` mode) or a phase whose every page is excluded by
   `--skip` prints nothing. The summary reports the pages and blocks checked per
   phase plus the total finding count split into gating and advisory.

## The `--skip` flag

Pass `--skip <name1,name2,...>` to exclude one or more policies or pages from a
run, for example while content is under active rewrite. A name is either a policy
folder (the directory name under `app/_mesh_policies/`) or the slug of another
mesh page (the file name under `app/mesh/` without extension):

```bash
node index.js --skip external-services,mesh-rate-limit
node index.js --skip hostnamegenerator@v2
```

A plain name applies to every major. To exclude the page in one major only,
qualify the name with the major: `--skip hostnamegenerator@v2` skips the
`app/mesh/v2/hostnamegenerator.md` page while the same slug in the latest tree
is still checked.

The listed names are filtered out of every class's source and built-page globs
before the build-precondition check and the instance-count rule run, so a
skipped page's missing or mismatched build output no longer fails the run. Every
other page is still checked. The run summary always names the requested skip
list, so a skip (or a typo'd, unmatched name) stays visible in the output.

## The `--terraform-validate` flag

Pass `--terraform-validate=off|warn|gate` to control the provider-schema check
of the terraform blocks. The default is `gate`: a finding is printed, counted as
gating, and makes the run exit non-zero. `warn` is an explicit opt-in that
keeps findings advisory: they are printed and counted, but do not affect the
exit status. `off` skips the check. The grammar check always runs. `--skip`
remains the escape hatch for policies the provider does not support.

One skip is standing: the workflow runs with `--skip external-services@v2`
because the legacy `ExternalService` policy has no top-level `spec`, so its
Kubernetes tab renders a null `spec` (a known renderer defect, out of scope
here) and the run reports it as a gating finding. A later change that fixes
that transform should remove both this note and the skip.

When the provider pin (`kong/konnect-beta` in `lib/terraform.js`) is bumped,
re-dump the provider schema and re-run the gate before merging: a wrapper
attribute or resource rename in the new provider turns published blocks
invalid, and the gate run is what surfaces it.

## Requires a production build

The validator reads `dist/`, not the Markdown source. `jekyll-dev.yml` skips the
mesh policy and markdown page generators in a dev build, so a dev build produces
nothing to validate. Run `make build` first, or comment out the `skip:` section in
`jekyll-dev.yml`. A scoped `KONG_PRODUCTS=mesh exe/build` also produces every mesh
policy example page. Validate against a clean `dist/` (`make clean` first): a
build over an existing `dist/` can leave stale pages behind, and the validator
cannot tell a stale page from a fresh one.

## Requires the terraform binary

The validator shells out to `terraform`. Install terraform
(https://developer.hashicorp.com/terraform/downloads) and make sure `terraform`
is on PATH. The binary is only needed to check terraform blocks; pages without a
terraform panel validate without it, and `--terraform-validate=off` skips the
part that needs network access to registry.terraform.io for the provider
download. Set `MESH_VALIDATOR_TERRAFORM_BIN` to point at another binary or a
stub. Tests that exercise the grammar rule spawn the real binary; the
provider-schema tests point `MESH_VALIDATOR_TERRAFORM_BIN` at a stub, so the
suite never contacts a registry.

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
