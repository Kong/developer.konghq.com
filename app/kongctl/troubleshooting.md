---
title: Troubleshooting kongctl
content_type: reference
layout: reference

description: Common issues and solutions when using kongctl.

tools:
  - kongctl
  
works_on:
  - konnect

tags:
  - troubleshooting

breadcrumbs:
  - /kongctl/
---

This guide covers common issues and their solutions when using kongctl.

## Authentication issues

### "Authentication required" or "unauthorized" errors

**Symptom**: Commands fail with authentication errors

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

4. Check the token hasn't expired in {{site.konnect_short_name}}

5. Verify correct region:
   ```bash
   kongctl login --region us  # or eu, au
   ```

### Device flow timeout

**Symptom**: Browser authorization doesn't complete in time

**Solutions**:

1. Complete authorization within the time limit (usually 15 minutes)

2. If timeout occurs, start over:
   ```bash
   kongctl login
   ```

3. Check your browser isn't blocking the redirect

## Resource management issues

### Resources not found

**Symptom**: `kongctl get` returns empty or missing resources

**Possible causes**:

1. **Wrong region**: Verify your organization's region
   ```bash
   kongctl login --region eu  # match your org's region
   ```

2. **Insufficient permissions**: Check your {{site.konnect_short_name}} role has read access

3. **Resource doesn't exist**: Verify the resource name is correct
   ```bash
   kongctl get apis  # List all to find correct name
   ```

### "Resource already exists" errors

**Symptom**: `kongctl apply` fails saying resource exists

**Solutions**:

1. Use `adopt` to take control of existing resources:
   ```bash
   kongctl adopt -f config.yaml
   ```

2. Or update the resource:
   ```bash
   kongctl apply -f config.yaml  # Apply handles updates
   ```

3. Or delete and recreate:
   ```bash
   kongctl delete api my-api
   kongctl apply -f config.yaml
   ```

### "Plan state changed" errors

**Symptom**: `kongctl apply --plan plan.json` fails because state changed

**Cause**: {{site.konnect_short_name}} state changed between plan generation and apply

**Solutions**:

1. Regenerate the plan:
   ```bash
   kongctl plan -f config/ --output-file plan.json
   kongctl apply --plan plan.json
   ```

2. Or use direct apply (doesn't use saved plan):
   ```bash
   kongctl apply -f config/
   ```

## Declarative configuration issues

### YAML syntax errors

**Symptom**: "YAML parse error" or "invalid configuration"

**Solutions**:

1. Validate YAML syntax:
   ```bash
   yamllint config.yaml
   ```

2. Check common mistakes:
   - Incorrect indentation (use spaces, not tabs)
   - Missing colons
   - Unquoted special characters

3. Example of correct format:
   ```yaml
   apiVersion: v1
   kind: Portal
   metadata:
     name: my-portal
   spec:
     displayName: "My Portal"
   ```

### Missing required fields

**Symptom**: "field 'X' is required" error

**Solutions**:

1. Check resource reference docs for required fields: [Supported Resources](/kongctl/reference/supported-resources/)

2. Example with all required fields:
   ```yaml
   apiVersion: v1
   kind: API
   metadata:
     name: my-api        # Required
   spec:
     displayName: "API"  # Required
   ```

### Unexpected deletions with sync

**Symptom**: `kongctl sync` deletes resources you want to keep

**Cause**: Resources not in your configuration files are deleted by design

**Solutions**:

1. Preview changes first:
   ```bash
   kongctl diff -f config/
   # or
   kongctl plan -f config/
   ```

2. Add missing resources to configuration:
   ```bash
   kongctl dump --output-file current.yaml
   # Edit and merge into your config
   ```

3. Use `apply` instead of `sync` if you don't want deletions:
   ```bash
   kongctl apply -f config/  # No deletions
   ```

## Network and connectivity issues

### Timeout errors

**Symptom**: "request timeout" or "connection timeout"

**Solutions**:

1. Increase timeout:
   ```bash
   export KONGCTL_HTTP_TIMEOUT=60
   kongctl get apis
   ```

2. Check network connectivity:
   ```bash
   ping api.konghq.com
   ```

3. Verify proxy settings if behind a corporate firewall:
   ```bash
   export HTTPS_PROXY=http://proxy.example.com:8080
   ```

### SSL/TLS errors

**Symptom**: "certificate verify failed" or SSL errors

**Solutions**:

1. Update system certificates:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install ca-certificates

   # macOS
   brew install ca-certificates
   ```

2. Check system clock is accurate (affects certificate validation)

### Rate limiting

**Symptom**: "too many requests" or 429 errors

**Solutions**:

1. Add delays between operations:
   ```bash
   kongctl apply -f file1.yaml
   sleep 2
   kongctl apply -f file2.yaml
   ```

2. Batch operations in fewer files:
   ```yaml
   # Instead of multiple files, use one with ---
   apiVersion: v1
   kind: Portal
   ---
   apiVersion: v1
   kind: API
   ```

3. Contact Kong support if limits are too restrictive for your use case

## CI/CD issues

### Secrets not being loaded

**Symptom**: CI/CD pipeline fails with authentication errors despite setting secrets

**Solutions**:

1. Verify secret name matches environment variable:
   ```yaml
   # GitHub Actions
   env:
     KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
   ```

2. Check secret is set in correct environment/scope

3. Test authentication separately:
   ```bash
   kongctl get me
   ```

### Plan artifacts not found

**Symptom**: "plan file not found" in deployment job

**Solutions**:

1. Ensure artifact is uploaded/downloaded correctly:
   ```yaml
   # GitHub Actions
   - uses: actions/upload-artifact@v4
     with:
       name: plan
       path: plan.json

   - uses: actions/download-artifact@v4
     with:
       name: plan
   ```

2. Verify artifact path matches apply command:
   ```bash
   ls -la plan.json  # Verify file exists
   kongctl apply --plan plan.json
   ```

### Concurrent deployments conflict

**Symptom**: Multiple pipelines interfere with each other

**Solutions**:

1. Use pipeline locks/queues to serialize deployments

2. Use different configurations for different teams/environments

3. Enable concurrency limits in CI/CD platform:
   ```yaml
   # GitHub Actions
   concurrency:
     group: konnect-deploy
     cancel-in-progress: false
   ```

## Performance issues

### Slow plan/apply operations

**Symptom**: Commands take very long to complete

**Causes**:

1. Large number of resources
2. Network latency
3. Complex configuration

**Solutions**:

1. Split configurations by resource type:
   ```bash
   kongctl apply -f portals.yaml
   kongctl apply -f apis.yaml
   ```

2. Use parallel operations where safe (different resource types)

3. Check debug logs for bottlenecks:
   ```bash
   export KONGCTL_DEBUG=1
   kongctl apply -f config/
   ```

## Debugging

### Enable debug logging

See detailed operation logs:

```bash
export KONGCTL_DEBUG=1
export KONGCTL_LOG_LEVEL=debug
kongctl plan -f config/
```

Debug output includes:
* API requests and responses
* Authentication details
* Configuration parsing
* Error stack traces

### Verify configuration

Check configuration file is loaded:

```bash
cat ~/.config/kongctl/config.yaml
```

### Test API connectivity

Make a direct API call:

```bash
kongctl api /v3/portals
```

### Check version

Ensure you're running the latest version:

```bash
kongctl version --full
```

Update if needed:
```bash
# macOS
brew upgrade kong/kongctl/kongctl

# Linux
# Download latest from GitHub releases
```

## Getting help

If you're still experiencing issues:

1. Check [GitHub issues](https://github.com/Kong/kongctl/issues) for similar problems

2. Review [GitHub discussions](https://github.com/Kong/kongctl/discussions)

3. Open a new issue with:
   - kongctl version (`kongctl version --full`)
   - Operating system
   - Command that failed
   - Full error message
   - Debug logs (with sensitive data redacted)

4. Contact Kong support if you're an enterprise customer

## Related resources

* [Authentication guide](/kongctl/authentication/)
* [Environment variables](/kongctl/reference/environment-variables/)
* [Supported resources](/kongctl/reference/supported-resources/)
* [GitHub issues](https://github.com/Kong/kongctl/issues)
