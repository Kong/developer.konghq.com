# regenerate-admin-specs

Generate or regenerate the Kong Gateway Admin API OpenAPI specs for one or more versions and copy them into the correct directories in this repo.

## How it works

The script drives the [`kong-admin-spec-generator`](https://github.com/Kong/kong-admin-spec-generator) tool, which must be cloned as a sibling directory of this repo.

For each requested version it:

1. Starts a Kong Gateway Docker container via `make setup-kong` in the generator repo
2. Runs `make kong` to generate `work/openapi.yaml` from the live Admin API
3. Diffs the result against the existing spec in `api-specs/gateway/admin-ee/{version}/openapi.yaml`
4. Copies the new spec into place if there are changes
5. Cleans up the Docker containers and `work/` directory via `make clean`

Versions are processed sequentially — Docker containers conflict if run in parallel.

## Prerequisites

- Docker is running
- Port `8001` is free before each version run
- `kong-admin-spec-generator` is cloned as a sibling of this repo:

```
~/docs/
  developer.konghq.com/   ← this repo
  kong-admin-spec-generator/
```

## Usage

Run from the root of this repo:

```bash
./tools/regenerate-admin-specs/regenerate-admin-specs.sh [versions...] [image:tag]
```

### Regenerate a single version using the default image

```bash
./tools/regenerate-admin-specs/regenerate-admin-specs.sh 3.13
```

### Regenerate multiple versions

```bash
./tools/regenerate-admin-specs/regenerate-admin-specs.sh 3.11 3.12 3.13
```

### Regenerate with a custom image and tag

Useful for dev builds or release candidates. Provide the image and tag as `image:tag` — `kong/` is prepended automatically.

```bash
./tools/regenerate-admin-specs/regenerate-admin-specs.sh 3.13 kong-gateway-dev:3.13.0.0
```

When a custom `image:tag` is given it applies to all versions in the run.

## Output

The script prints a per-version log as it runs, then a summary at the end:

```
===== Summary =====
Updated specs:
  - 3.13
Already up to date:
  - 3.12
Skipped:
  - 3.11 (setup failed)
```

If a version fails during setup or generation, the script logs the reason, cleans up, and moves on to the next version.

