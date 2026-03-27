# Skill: Generate Admin API Specs

generate or regenerate the Kong Gateway Admin API OpenAPI specs for one or more versions and copy them into the correct directories in this repo.

## Usage

```
/regenerate-admin-specs [versions]
```

Examples:

- `/regenerate-admin-specs 3.13` — regenerate a single version
- `/regenerate-admin-specs 3.11 3.12 3.13` — regenerate specific versions

## What this skill does

1. Checks that the generator repo exists at `../kong-admin-spec-generator`
2. For each requested version:
   - Runs `DOCKER_IMAGE=kong/kong-gateway:{version} make setup-kong`
   - Runs `make kong` to generate the spec
   - Diffs the generated spec against the existing one in `api-specs/gateway/admin-ee/{version}/openapi.yaml`
   - Copies the new spec into place if there are changes
   - Runs `make clean`
3. Reports a summary of what changed per version
4. Flags any plugin API specs that may need manual follow-up based on schema changes

## Important notes

- Must be run from `../kong-admin-spec-generator` directory
- Requires Docker to be running
- Port 8001 must be free before each run — the Makefile checks this
- Always copy the spec BEFORE running `make clean`, which deletes the `work/` directory
- Some older versions (e.g. 3.4) may fail if the generator tries to fetch entities that don't exist in that version. If setup fails, skip the version and report why.
- The generated spec always lands at `work/openapi.yaml`
- Destination: `api-specs/gateway/admin-ee/{version}/openapi.yaml`

## Plugin spec follow-up

After regenerating, check whether any of the following plugin specs need updating based on schema changes in the new admin spec:

- `api-specs/plugins/graphql-rate-limiting-advanced/openapi.yaml` — watch for changes to `GraphQLCostDecoration`

If schemas changed, flag them for manual review rather than auto-updating.

## Instructions for Claude

When this skill is invoked:

1. Confirm which versions will be regenerated before starting
2. Resolve paths dynamically:
   - `DOCS_REPO` = the root of this repository (the `developer.konghq.com` checkout). Determine it by running `git rev-parse --show-toplevel` from the current working directory.
   - `GENERATOR_DIR` = `$(dirname $DOCS_REPO)/kong-admin-spec-generator` (sibling directory to this repo)
   - Verify `GENERATOR_DIR` exists before proceeding. If it doesn't, tell the user to clone `kong-admin-spec-generator` as a sibling of this repo and stop.
3. Run each version sequentially (not in parallel — Docker containers conflict)
4. For each version:
   - Run `cd $GENERATOR_DIR && DOCKER_IMAGE=kong/kong-gateway:{version} make setup-kong`. If it fails, log the error, skip the version, continue.
   - Run `make kong` from `$GENERATOR_DIR`. If it fails, run `make clean` and skip.
   - Diff: `diff $GENERATOR_DIR/work/openapi.yaml $DOCS_REPO/api-specs/gateway/admin-ee/{version}/openapi.yaml`
   - If diff exits 1 (changes exist), copy with `cp $GENERATOR_DIR/work/openapi.yaml $DOCS_REPO/api-specs/gateway/admin-ee/{version}/openapi.yaml` and report a brief summary of what changed
   - If diff exits 0 (no changes), note that the spec is already up to date
   - Run `make clean` from `$GENERATOR_DIR`
5. If any plugin specs may need follow-up, call that out explicitly
