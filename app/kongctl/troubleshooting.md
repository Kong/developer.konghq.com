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

This guide covers common issues and their solutions when using kongctl.

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

## Debugging

### Enable debug logging

You can enable debugging to see detailed operation logs:

```bash
export KONGCTL_DEBUG=1
export KONGCTL_LOG_LEVEL=debug
kongctl plan -f config/
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

## Getting help

If you're still experiencing issues, do the following:

1. Check [GitHub issues](https://github.com/Kong/kongctl/issues) for similar problems.
	
2. Review [GitHub discussions](https://github.com/Kong/kongctl/discussions).

3. Open a new issue with:
   - kongctl version (`kongctl version --full`)
   - Operating system
   - Command that failed
   - Full error message
   - Debug logs (with sensitive data redacted)

4. Contact [Kong Support](https://support.konghq.com) if you're an enterprise customer.
