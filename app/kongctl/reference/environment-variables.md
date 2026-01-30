---
title: Environment variables
content_type: reference
description: Environment variables used by kongctl for configuration and authentication.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - cli
breadcrumbs:
  - /kongctl/
  - /kongctl/reference/
---

kongctl supports environment variables for configuration, authentication, and customization.

## Authentication

### KONGCTL_DEFAULT_KONNECT_PAT

**Type:** String
**Description:** Personal access token for {{site.konnect_short_name}} authentication
**Usage:** CI/CD pipelines and automation

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="kpat_your-token-here"
kongctl get apis
```

This is the recommended way to authenticate in non-interactive environments.

{:.warning}
> **Security**: Never commit this value to version control. Use secrets management in CI/CD platforms.

## Configuration

### XDG_CONFIG_HOME

**Type:** String (Path)
**Description:** Base directory for kongctl configuration files
**Default:** `~/.config`

Configuration is stored in `$XDG_CONFIG_HOME/kongctl/config.yaml`.

```bash
export XDG_CONFIG_HOME=/custom/config/path
kongctl login
# Creates /custom/config/path/kongctl/config.yaml
```

### KONGCTL_CONFIG_DIR

**Type:** String (Path)
**Description:** Override kongctl configuration directory
**Default:** `$XDG_CONFIG_HOME/kongctl` or `~/.config/kongctl`

```bash
export KONGCTL_CONFIG_DIR=/path/to/config
kongctl login
```

### KONGCTL_DEFAULT_REGION

**Type:** String
**Description:** Default {{site.konnect_short_name}} region
**Values:** `us`, `eu`, `au`
**Default:** `us`

```bash
export KONGCTL_DEFAULT_REGION=eu
kongctl login
# Authenticates to EU region by default
```

### KONGCTL_DEFAULT_PROFILE

**Type:** String
**Description:** Default profile to use
**Default:** `default`

```bash
export KONGCTL_DEFAULT_PROFILE=production
kongctl get apis
# Uses production profile
```

## Output and formatting

### KONGCTL_NO_COLOR

**Type:** Boolean
**Description:** Disable colored output
**Values:** `1`, `true`, or any non-empty value enables
**Default:** Not set (colors enabled)

```bash
export KONGCTL_NO_COLOR=1
kongctl get apis
# Output without colors
```

Useful for:
* CI/CD logs
* Piping to files
* Systems that don't support ANSI colors

### KONGCTL_OUTPUT_FORMAT

**Type:** String
**Description:** Default output format for commands
**Values:** `table`, `json`, `yaml`
**Default:** `table`

```bash
export KONGCTL_OUTPUT_FORMAT=json
kongctl get apis
# Outputs JSON by default
```

Can be overridden with `--output` flag:
```bash
kongctl get apis --output yaml
```

## Debugging

### KONGCTL_DEBUG

**Type:** Boolean
**Description:** Enable debug logging
**Values:** `1`, `true`, or any non-empty value enables
**Default:** Not set

```bash
export KONGCTL_DEBUG=1
kongctl get apis
# Shows detailed debug information
```

Debug output includes:
* API requests and responses
* Authentication details
* Configuration loading
* Error stack traces

### KONGCTL_LOG_LEVEL

**Type:** String
**Description:** Logging level
**Values:** `debug`, `info`, `warn`, `error`
**Default:** `info`

```bash
export KONGCTL_LOG_LEVEL=debug
kongctl plan -f config/
```

## HTTP settings

### KONGCTL_HTTP_TIMEOUT

**Type:** Integer (seconds)
**Description:** HTTP request timeout
**Default:** `30`

```bash
export KONGCTL_HTTP_TIMEOUT=60
kongctl get apis
```

### KONGCTL_HTTP_RETRY

**Type:** Integer
**Description:** Number of retry attempts for failed requests
**Default:** `3`

```bash
export KONGCTL_HTTP_RETRY=5
kongctl apply -f config/
```

### HTTPS_PROXY / HTTP_PROXY

**Type:** String (URL)
**Description:** Proxy server for HTTP/HTTPS requests
**Default:** Not set

```bash
export HTTPS_PROXY=http://proxy.example.com:8080
kongctl get apis
```

## CI/CD examples

### GitHub Actions

```yaml
- name: Deploy to Konnect
  env:
    KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
    KONGCTL_DEFAULT_REGION: us
    KONGCTL_NO_COLOR: 1
    KONGCTL_LOG_LEVEL: info
  run: kongctl apply -f config/
```

### GitLab CI

```yaml
deploy:
  script:
    - kongctl apply -f config/
  variables:
    KONGCTL_DEFAULT_KONNECT_PAT: $KONNECT_PAT
    KONGCTL_DEFAULT_REGION: eu
    KONGCTL_NO_COLOR: "1"
```

### Jenkins

```groovy
environment {
    KONGCTL_DEFAULT_KONNECT_PAT = credentials('konnect-pat')
    KONGCTL_DEFAULT_REGION = 'us'
    KONGCTL_NO_COLOR = '1'
}
```

### Docker

```bash
docker run -e KONGCTL_DEFAULT_KONNECT_PAT="$KONNECT_PAT" \
           -e KONGCTL_DEFAULT_REGION=us \
           -v $(pwd)/config:/config \
           kongctl apply -f /config
```

## Precedence

When the same configuration is set in multiple places, kongctl uses this precedence (highest to lowest):

1. Command-line flags (e.g., `--pat`, `--region`)
2. Environment variables
3. Profile configuration in `config.yaml`
4. Default values

Example:
```bash
# config.yaml has region: us
# Environment has KONGCTL_DEFAULT_REGION=eu
# Command uses --region au

kongctl get apis --region au
# Uses au (command-line flag wins)
```

## Related resources

* [Authentication guide](/kongctl/authentication/)
* [CI/CD integration](/kongctl/declarative/ci-cd/)
* [Configuration file format](/kongctl/declarative/)
