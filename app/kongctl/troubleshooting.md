---
title: Troubleshooting kongctl
content_type: reference
layout: reference

description: Common issues and solutions when using kongctl.
beta: true
tools:
  - kongctl
  
works_on:
  - konnect

tags:
  - troubleshooting

breadcrumbs:
  - /kongctl/

related_resources:
   - text: Learn kongctl authorization options
     url: /kongctl/authentication/
   - text: Guide for managing {{site.konnect_short_name}} resources declaratively
     url: /kongctl/declarative/
   - text: kongctl configuration reference guide
     url: /kongctl/config/
   - text: Using kongctl and deck for full API platform management
     url: /kongctl/kongctl-and-deck/
---

This reference covers common issues and their solutions when using kongctl.

## Common issues

### "No changes detected" when changes exist

**Symptom**: Modified configuration but plan shows no changes, or resources appear unchanged after apply.

**Causes**:
1. Resource already matches desired state
2. Invalid resource references
3. Namespace mismatch

**Solutions**:

Dump current state and compare with your configuration:
```bash
kongctl dump declarative --resources <your-resource-type> --output-file current-state.yaml
# or
kongctl dump tf-import --resources <your-resource-type>
diff current-state.yaml your-config.yaml
```

Check resource references are spelled correctly and match a declared `ref`:
```bash
grep "ref:" your-config.yaml
```

Verify the resource has the expected namespace label in {{site.konnect_short_name}}:
```bash
kongctl get apis -o json
```

### "Resource not found" errors

**Symptom**: Error during plan or apply referencing a non-existent resource.

**Example**:
```sh
Error: resource "my-portal" not found
```

**Solutions**:

Check whether the resource exists:
```bash
kongctl get portals | grep my-portal
```

Verify the ref spelling in your configuration files:
```bash
grep -n "my-portal" *.yaml
```

Ensure dependencies are applied first when resources reference each other:
```bash
kongctl apply -f portals.yaml
kongctl apply -f apis.yaml
kongctl apply -f publications.yaml
```

## Authentication issues

### "Authentication required" or "unauthorized" errors

**Symptom**: Commands fail with authentication errors.

**Solutions**:

1. Verify you're logged in:
   
   ```bash
   kongctl get me
   ```

2. Re-authenticate:
   
   ```bash
   kongctl logout
   kongctl login
   ```

3. If using a PAT, verify it's set:
   
   ```bash
   echo $KONGCTL_DEFAULT_KONNECT_PAT | head -c 20
   ```

4. Check that the token hasn't expired in {{site.konnect_short_name}}.
	
5. Verify that `region` is configured as expected.

### Browser login timeout

**Symptom**: Browser authorization doesn't complete in time.

**Solutions**:

1. Complete authorization within the time limit (usually 15 minutes).
	
2. If timeout occurs, start over:

	```bash
	kongctl login
  ```

3. Verify that your browser isn't blocking the redirect.

### Multiple authentication methods conflict

**Symptom**: Unexpected authentication behavior or wrong credentials being used.

**Solution**: Check and clear auth methods, if needed.

kongctl resolves authentication in this priority order (highest to lowest):
1. `--pat` flag
2. `KONGCTL_<PROFILE>_KONNECT_PAT` environment variable
3. Stored token from `kongctl login`

To start fresh and clear all auth methods:
```bash
unset KONGCTL_DEFAULT_KONNECT_PAT
kongctl logout
kongctl login
```

{:.info}
> If you manage profiles outside the default path, you may also need to remove `~/.config/kongctl/.<profile>-konnect-token.json` manually.

## Configuration errors

### YAML parsing errors

**Symptom**:
```sh
Error: yaml: unmarshal errors:
  line 10: cannot unmarshal !!str `true` into bool
```
{:.no-copy-code}

**Solution**: Ensure field values use the correct YAML type. For example, for a boolean value:

```yaml
authentication_enabled: true
```

### Duplicate resource references

**Symptom**:
```sh
Error: duplicate resource ref "my-api" found
```
{:.no-copy-code}

**Solution**: Each `ref` must be unique across all loaded configuration files. Find duplicates and rename them:

```bash
grep -n "ref: my-api" *.yaml
```

### Invalid field values

**Symptom**:
```sh
Error: invalid value for field "visibility": "internal"
```
{:.no-copy-code}

**Solution**: Check the allowed values in the [supported resources reference](/kongctl/supported-resources/):

```yaml
api_publications:
  - ref: my-pub
    visibility: private  # Allowed values: public, private
```

## File loading and YAML tags

### File not found errors

**Symptom**:
```sh
Error: failed to process file tag: file not found: ./specs/api.yaml
```
{:.no-copy-code}

**Solutions**: Look for the following common errors:

1. **Incorrect relative path**: paths must be relative to the config file, not the working directory:
   
   ```yaml
   spec: !file ./specs/api.yaml
   ```

2. **Wrong base directory**: If your spec file is outside the config file's directory:

   ```
   project/
   ├── config/
   │   └── main.yaml
   └── specs/
       └── api.yaml
   ```
   {:.no-copy-code}

   In `config/main.yaml`, you would access the file like this:
   ```yaml
   spec: !file ../specs/api.yaml
   ```

   If you see `path resolves outside base dir`, use the `--base-dir` flag or the `KONGCTL_DEFAULT_KONNECT_DECLARATIVE_BASE_DIR` environment variable to set an allowed boundary.

3. **File permissions**: Verify the file is readable:

   ```bash
   ls -la ./specs/api.yaml
   chmod 644 ./specs/api.yaml
   ```

### Invalid YAML tag extraction path

**Symptom**:
```sh
Error: path not found: info.nonexistent.field
```
{:.no-copy-code}

**Solution**: 
1. Review the YAML path closely, looking for typos or incorrect paths.
1. Use dot notation for arrays instead of bracket array syntax:

   ```yaml
   server: !file ./spec.yaml#servers.0.url
   ```

### Malformed YAML tag syntax

**Symptom**:
```sh
Error: failed to parse file reference: invalid tag format
```
{:.no-copy-code}

**Solution**: Check the correct map format for `!file`:

```yaml
title: !file
  path: ./spec.yaml
  extract: info.title
```

### Large file errors

**Symptom**:
```sh
Error: file size exceeds limit: ./large-spec.yaml (12MB > 10MB limit)
```
{:.no-copy-code}

**Solutions**:

Split large files, or extract only the values you need rather than loading the entire file. 
For example, with a large file named `huge-openapi-spec.yaml`, access only the data you need:

```yaml
name: !file ./huge-openapi-spec.yaml#info.title
version: !file ./huge-openapi-spec.yaml#info.version
```

## Cross-resource references

### Unknown resource references

**Symptom**:
```sh
Error: resource "my-api" references unknown portal: unknown-portal
```
{:.no-copy-code}

**Solutions**: Look for the following common errors:

1. **Typo in the ref value**: The ref must exactly match the `ref` field of the target resource:

   ```yaml
   portals:
     - ref: developer-portal  # Exact ref value

   api_publications:
     - ref: api-pub
       portal: developer-portal # Matches the portal ref
   ```

2. **Nested vs separate resource conflict**: Don't declare the same ref both nested and at the root:

   ```yaml
   # Wrong - v1 is declared twice
   apis:
     - ref: my-api
       versions:
         - ref: v1  # Nested

   api_versions:
     - ref: v1      # Conflict
       api: my-api
   ```

### External ID vs reference confusion

**Symptom**:
```sh
Error: resource references unknown control_plane_id: my-control-plane
```
{:.no-copy-code}

**Solution**: Fields like `control_plane_id` expect a {{site.konnect_short_name}} UUID, not a declarative `ref`. 
Use `!ref` to resolve a declarative resource's ID:

```yaml
api_implementations:
  - ref: impl
    service:
      control_plane_id: !ref my-control-plane#id
```

## Planning issues

### Plan generation hangs

**Symptom**: `kongctl plan` doesn't complete.

**Solutions**:

Enable debug logging to see where it's stuck:
```bash
kongctl plan -f config.yaml --log-level debug
```

Test network connectivity to {{site.konnect_short_name}}:
```bash
kongctl get portals
```

Try planning a smaller configuration to isolate the issue:
```bash
kongctl plan -f single-resource.yaml
```

### Circular dependencies

**Symptom**:
```sh
Error: circular dependency detected: api1 -> api2 -> api1
```
{:.no-copy-code}

**Solution**: Restructure your configuration to break the cycle by introducing a shared base resource or removing the circular reference.

## Plan artifact debugging

### Invalid plan file

**Symptom**:
```sh
Error: failed to read plan: invalid plan format
```
{:.no-copy-code}

**Solutions**:

Validate the plan file is valid JSON:
```bash
cat plan.json | jq . > /dev/null
```

Regenerate the plan if it's corrupted:
```bash
kongctl plan -f config.yaml --output-file plan.json
```

### Stale plan artifact

**Symptom**: You see the following error:
```sh
Error: plan is out of date - resource already exists
```
{:.no-copy-code}

**Solution**: Regenerate the plan to reflect the current live state:
```bash
kongctl plan -f config.yaml --output-file new-plan.json
```

### Inspecting plan contents

View the plan summary:
```bash
jq '.summary' plan.json
```

List all planned operations:
```bash
jq '.changes[] | {op: .operation, type: .resource_type, ref: .resource_ref}' plan.json
```

Filter to specific operations:
```bash
# Show only CREATE operations
jq '.changes[] | select(.operation == "CREATE")' plan.json
```

## Execution failures

### Partial apply failures

**Symptom**: Some resources are created successfully, others fail. Apply reports errors for specific resources.

**Solution**: Fix the failing resource configuration and re-run apply. The apply command is idempotent, so existing resources are skipped:
```bash
kongctl apply -f config.yaml
```

### Protected resource blocking changes

**Symptom**: You see the following error:
```
Error: Cannot modify protected resource "production-api"
```

**Solution**: Temporarily set `protected: false`, apply your changes, then re-enable protection:
```yaml
apis:
  - ref: production-api
    kongctl:
      protected: false  # Changed from true
```

### Sync deleting unexpected resources

**Symptom**: Resources are deleted that shouldn't be.

**Prevention**: Always dry-run before syncing, especially in production:
```bash
kongctl sync -f config.yaml --dry-run
```

Use namespaces to limit sync scope to only your team's resources. Check which resources are managed by kongctl before syncing:
```bash
kongctl get apis -o json
```

## Performance issues

### Slow plan generation

**Symptom**: Plans take a long time to generate.

**Solution**: Check the logs to identify the problem, and split large configurations as needed.

Enable trace logging to identify slow API calls:
```bash
kongctl plan -f config.yaml --log-level trace
```

Split large configurations into smaller files and plan them separately:
```bash
kongctl plan -f apis-batch-1.yaml
kongctl plan -f apis-batch-2.yaml
```

Check for 429 (rate limiting) status codes in trace logs.

### High memory usage with file tags

When loading the same large file multiple times, extract only the fields you need. Files are cached within a single execution, so referencing the same file multiple times is efficient:

```yaml
# Instead of loading the full spec repeatedly
apis:
  - ref: api-1
    name: !file ./common.yaml#api.name        # Loaded and cached
    description: !file ./common.yaml#api.desc # Uses cache
  - ref: api-2
    team: !file ./common.yaml#team.name       # Uses cache
```

## Debugging

### Enable debug logging

Show detailed operation logs:

```bash
kongctl apply -f config.yaml --log-level debug
```

Show API requests and responses:

```bash
kongctl apply -f config.yaml --log-level trace
```

You can also set these via environment variables:

```bash
export KONGCTL_LOG_LEVEL=debug
kongctl plan -f config/
```

### Trace log analysis

When trace logging is enabled, look for:
- `4xx`/`5xx` HTTP status codes
- Slow response times
- Unexpected response bodies

Example trace output:
```
time=2024-01-15T12:00:00.000Z level=TRACE msg="HTTP request" method=GET url=https://global.api.konghq.com/v2/portals
time=2024-01-15T12:00:01.000Z level=TRACE msg="HTTP response" status=200 duration=1s
```
{:.no-copy-code}

### Step-by-step debugging workflow

Use this sequence to isolate issues:

1. Validate YAML syntax:
   ```bash
   cat config.yaml | python -m yaml
   ```
1. Test authentication:
   ```bash
   kongctl get portals
   ```
1. Generate plan with debug logging:
   ```bash
   kongctl plan -f config.yaml --log-level debug --output-file plan.json
   ```
1. Review the plan:
   ```bash
   cat plan.json | jq '.changes'
   ```
1. Dry-run the apply:
   ```bash
   kongctl apply --plan plan.json --dry-run
   ```
1. Apply with trace logging:
   ```bash
   kongctl apply --plan plan.json --log-level trace
   ```

### Verify configuration

Verify that the configuration file is valid:

```bash
cat ~/.config/kongctl/config.yaml
```

### Test API connectivity

Make a direct [API](/api/) call to test API connectivity:

```bash
kongctl api /v3/portals
```

### Check version

Ensure you're running the [latest version](https://github.com/kong/kongctl/releases):

```bash
kongctl version --full
```

Update kongctl if needed [following the install instructions for your platform](/kongctl).

## Quick reference

### Error patterns

<!--vale off-->
{% table %}
columns:
  - title: Error
    key: error
  - title: Likely cause
    key: cause
  - title: Quick fix
    key: fix
rows:
  - error: "unauthorized"
    cause: Expired token
    fix: "`kongctl login`"
  - error: "not found"
    cause: Wrong resource reference
    fix: "Check spelling of `ref` values"
  - error: "invalid value"
    cause: Wrong type or format
    fix: Check the supported resources reference
  - error: "file not found"
    cause: Wrong file path
    fix: Use paths relative to the config file
  - error: "protected resource"
    cause: Protection enabled
    fix: "Temporarily set `protected: false`"
  - error: "circular dependency"
    cause: Resource reference loop
    fix: Restructure to remove the cycle
  - error: "path not found"
    cause: Invalid extraction path
    fix: Check the YAML structure of the source file
  - error: "exceeds limit"
    cause: File too large
    fix: Split the file or extract only needed values
{% endtable %}
<!--vale on-->

### Useful environment variables

```bash
# Set log level globally
export KONGCTL_LOG_LEVEL=debug

# Use a specific profile
export KONGCTL_PROFILE=production

# Set PAT for the default profile
export KONGCTL_DEFAULT_KONNECT_PAT="your-token-here"
```

## Prevention tips

1. Always dry-run (`--dry-run`) before applying in production.
2. Use version control for all configuration files.
3. Test changes in a lower environment before production.
4. Use namespaces to isolate changes between teams and environments.
5. Enable trace logging when debugging unexpected behavior.
6. Review plans before applying by using the two-phase plan and apply workflow.
7. Validate YAML syntax before deploying.
8. Check file paths are relative to the config file, not the working directory.
9. Monitor file sizes to stay under the 10MB limit.
10. Use `protected: true` on production resources to prevent accidental deletion.

## Getting help

If you're still experiencing issues, do the following:

1. Check [GitHub issues](https://github.com/Kong/kongctl/issues) for similar problems.
	
2. Review [GitHub discussions](https://github.com/Kong/kongctl/discussions).

3. Open a new issue containing the following information:
   - kongctl version (`kongctl version --full`)
   - Operating system
   - Command that failed
   - Full error message
   - Debug logs (with sensitive data redacted)

4. Contact [Kong Support](https://support.konghq.com) if you're an enterprise customer.
