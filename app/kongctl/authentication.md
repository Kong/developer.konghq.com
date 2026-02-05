---
title: Authentication with kongctl
content_type: concept
description: Learn how to authenticate kongctl to Kong Konnect using device flow or personal access tokens.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - authentication
  - cli
breadcrumbs:
  - /kongctl/
related_resources:
  - text: Environment variables reference
    url: /kongctl/reference/environment-variables/
---

kongctl requires authentication to interact with {{site.konnect_short_name}}. This guide covers the two supported authentication methods.

## Authentication methods

| Method | Best For | How It Works |
|--------|----------|--------------|
| **Device Flow** | Interactive use | Browser-based authorization |
| **Personal Access Token** | CI/CD, automation | API token passed via flag or environment variable |

## Device flow (recommended for interactive use)

Device flow provides browser-based authentication with automatic token refresh.

### Login

```bash
kongctl login
```

This command:
1. Displays a URL and verification code
2. Opens your default browser
3. Prompts you to authorize kongctl
4. Stores credentials locally after successful authorization

### Verify authentication

```bash
kongctl get me
```

You should see your {{site.konnect_short_name}} user information.

### Logout

Clear stored credentials:

```bash
kongctl logout
```

### Configuration storage

Credentials are stored in:
```
~/.config/kongctl/config.yaml
```

Or if `XDG_CONFIG_HOME` is set:
```
$XDG_CONFIG_HOME/kongctl/config.yaml
```

Example configuration:
```yaml
currentProfile: default
profiles:
  default:
    region: us
    authType: device-flow
```

### Multi-region support

Specify region during login:

```bash
kongctl login --region eu
```

Supported regions:
* `us` (United States - default)
* `eu` (Europe)
* `au` (Australia)

## Personal access tokens

Personal access tokens (PATs) are recommended for non-interactive scenarios like CI/CD pipelines.

### Create a token

1. Log in to {{site.konnect_short_name}}
2. Navigate to **Personal Access Tokens**
3. Click **Generate Token**
4. Give it a descriptive name (e.g., "CI/CD Pipeline")
5. Set expiration and permissions
6. Copy the token (shown only once)

### Use via environment variable

Set the `KONGCTL_DEFAULT_KONNECT_PAT` environment variable:

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="kpat_your-token-here"
```

Then run commands normally:
```bash
kongctl get apis
```

### Use via flag

Pass the token with `--pat`:

```bash
kongctl get apis --pat "kpat_your-token-here"
```

### Use in CI/CD

Store the token as a secret in your CI/CD platform:

**GitHub Actions:**
```yaml
- name: Deploy to Konnect
  env:
    KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
  run: kongctl apply -f config/
```

**GitLab CI:**
```yaml
deploy:
  script:
    - kongctl apply -f config/
  variables:
    KONGCTL_DEFAULT_KONNECT_PAT: $KONNECT_PAT
```

**Jenkins:**
```bash
environment {
    KONGCTL_DEFAULT_KONNECT_PAT = credentials('konnect-pat')
}
```

{:.warning}
> **Security**: Never commit tokens to version control. Always use secrets management.

## Multiple profiles

Kong supports multiple profiles for managing different {{site.konnect_short_name}} organizations or regions.

### Create a profile

```bash
kongctl login --profile production --region us
kongctl login --profile staging --region eu
```

### Use a profile

```bash
kongctl get apis --profile production
```

### List profiles

Configuration file shows all profiles:

```yaml
currentProfile: production
profiles:
  production:
    region: us
    authType: device-flow
  staging:
    region: eu
    authType: device-flow
```

### Switch default profile

Edit `~/.config/kongctl/config.yaml` and change `currentProfile`.

## Troubleshooting

### Authentication failures

**Symptom:** Commands fail with "unauthorized" or "authentication required"

**Solutions:**

1. Verify you're logged in:
   ```bash
   kongctl get me
   ```

2. Check token expiration (if using PAT)

3. Re-authenticate:
   ```bash
   kongctl logout
   kongctl login
   ```

4. Verify region matches your organization:
   ```bash
   kongctl login --region us  # or eu, au
   ```

### Token not found

**Symptom:** "token not found" error

**Solutions:**

1. Login first:
   ```bash
   kongctl login
   ```

2. Or set PAT environment variable:
   ```bash
   export KONGCTL_DEFAULT_KONNECT_PAT="your-token"
   ```

### Wrong region

**Symptom:** Resources not found or empty lists

**Solutions:**

1. Check your organization's region in {{site.konnect_short_name}}

2. Login with correct region:
   ```bash
   kongctl login --region eu
   ```

3. Or specify region per command:
   ```bash
   kongctl get apis --region eu
   ```

### Permission denied

**Symptom:** "insufficient permissions" or "forbidden"

**Solutions:**

1. Verify your {{site.konnect_short_name}} role has required permissions

2. If using PAT, ensure the token has necessary scopes

3. Check token hasn't been revoked

## Security best practices

### For interactive use

* Use device flow when possible
* Logout when done on shared machines:
  ```bash
  kongctl logout
  ```
* Protect your config file:
  ```bash
  chmod 600 ~/.config/kongctl/config.yaml
  ```

### For automation

* Store PATs as encrypted secrets
* Use short-lived tokens when possible
* Rotate tokens regularly
* Use separate tokens per pipeline/environment
* Never log tokens in CI/CD output
* Revoke tokens immediately if compromised

### Token rotation

1. Generate new token in {{site.konnect_short_name}}
2. Update secret in CI/CD platform
3. Verify new token works
4. Revoke old token

## Related resources

* [CI/CD integration guide](/kongctl/declarative/ci-cd/)
* [Environment variables reference](/kongctl/reference/environment-variables/)
