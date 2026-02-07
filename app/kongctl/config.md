---
title: Configuration
description: Learn how to configure kongctl using configuration files, environment variables, and command-line flags.

beta: true

content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

tags:
  - cli

breadcrumbs:
  - /kongctl/
---

kongctl provides a flexible configuration system supporting configuration files, environment variables, and command-line flags. This enables you to customize behavior for different environments, teams, and CI/CD pipelines.

## Configuration overview

kongctl configuration follows a layered approach with the following precedence (highest to lowest):

1. **Command-line flags** - Explicit flags like `--pat`, `--region`, `--output`
2. **Environment variables** - `KONGCTL_<PROFILE>_<PATH>` variables
3. **Profile configuration** - Values in `config.yaml`
4. **Default values** - Built-in defaults

This allows you to set reasonable defaults in configuration files while overriding them as needed for specific commands or environments.

## Configuration files and profiles

### Configuration directory

kongctl stores configuration in `$XDG_CONFIG_HOME/kongctl` (defaulting to `~/.config/kongctl`). The main configuration file is `config.yaml`.

```bash
# View your configuration directory
ls -la ~/.config/kongctl/

# Typical contents:
# config.yaml                    # Main configuration
# .default-konnect-token.json    # Default profile auth token
# .production-konnect-token.json # Production profile auth token
```

### Profiles

Profiles are named collections of configuration values. Use profiles to maintain separate configurations for different environments, regions, or teams.

**Basic profile structure**:

```yaml
default:
  output: text
  konnect:
    region: us

production:
  output: json
  konnect:
    region: us

staging:
  output: yaml
  konnect:
    region: eu
```

**Using profiles**:

```bash
# Use default profile (implicit)
kongctl get apis

# Specify profile with flag
kongctl get apis --profile production

# Set profile via environment variable
export KONGCTL_PROFILE=production
kongctl get apis
```

### Configurable settings

Many command-line flags can be configured in `config.yaml`. Check command help text for "Config path" annotations:

```bash
kongctl get apis --help

# Output shows:
# -o, --output string        Configures the format of data written to STDOUT.
#                              - Config path: [ output ]
#                              - Allowed    : [ json|yaml|text ] (default "text")
```

The config path indicates where to set the value in your configuration file. For nested paths like `konnect.region`, use YAML nesting:

```yaml
default:
  output: json
  konnect:
    region: eu
    base-url: https://custom.api.konghq.com
```

## Authentication

kongctl supports multiple authentication methods for accessing {{site.konnect_short_name}} APIs.

### Device flow (recommended)

The `kongctl login` command uses OAuth device flow for interactive authentication:

```bash
kongctl login
```

This command:
1. Generates a unique device code
2. Displays a URL and code for you to enter in your browser
3. Waits for you to authenticate and authorize the CLI
4. Stores the access token and refresh token locally

**Token storage**: Tokens are saved to `$XDG_CONFIG_HOME/kongctl/.<profile>-konnect-token.json`

**Per-profile authentication**:

```bash
# Authenticate default profile
kongctl login

# Authenticate production profile
kongctl login --profile production
```

**Logout**:

```bash
# Clear default profile credentials
kongctl logout

# Clear specific profile credentials
kongctl logout --profile production
```

### Personal Access Token (PAT)

For automation and CI/CD, use Personal Access Tokens instead of interactive login.

**Command-line flag**:

```bash
kongctl get apis --pat kpat_your-token-here
```

**Environment variable** (recommended for CI/CD):

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="kpat_your-token-here"
kongctl get apis
```

**Profile-specific environment variable**:

```bash
export KONGCTL_PRODUCTION_KONNECT_PAT="kpat_production-token"
kongctl get apis --profile production
```

**Configuration file** (not recommended for security):

```yaml
default:
  konnect:
    pat: kpat_your-token-here  # Avoid storing tokens in config files
```

{:.warning}
> **Security**: Never commit PATs to version control. Use secrets management in CI/CD platforms and environment variables for token storage.

### Authentication precedence

When multiple authentication methods are configured:

1. `--pat` flag (highest priority)
2. `KONGCTL_<PROFILE>_KONNECT_PAT` environment variable
3. `config.yaml` pat field
4. Device flow token file (`.default-konnect-token.json`)

## Environment variables

kongctl uses environment variables for configuration and to override settings.

### Variable naming pattern

Environment variables follow the pattern:

```
KONGCTL_<PROFILE>_<PATH>
```

Where:
- `<PROFILE>` is the profile name in uppercase (e.g., `DEFAULT`, `PRODUCTION`)
- `<PATH>` is the config path in uppercase with underscores replacing dots

**Examples**:

```bash
# Set output format for default profile
export KONGCTL_DEFAULT_OUTPUT=json

# Set region for production profile
export KONGCTL_PRODUCTION_KONNECT_REGION=eu

# Set base URL for staging profile
export KONGCTL_STAGING_KONNECT_BASE_URL=https://staging.api.konghq.com
```

### Authentication variables

#### KONGCTL_DEFAULT_KONNECT_PAT

**Type:** String
**Description:** Personal access token for {{site.konnect_short_name}} authentication
**Usage:** CI/CD pipelines and automation

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="kpat_your-token-here"
kongctl get apis
```

Replace `DEFAULT` with your profile name (e.g., `KONGCTL_PRODUCTION_KONNECT_PAT`).

### Configuration variables

#### XDG_CONFIG_HOME

**Type:** String (Path)
**Description:** Base directory for XDG-compliant configuration files
**Default:** `~/.config`

```bash
export XDG_CONFIG_HOME=/custom/config/path
kongctl login
# Creates /custom/config/path/kongctl/config.yaml
```

#### KONGCTL_CONFIG_DIR

**Type:** String (Path)
**Description:** Override kongctl-specific configuration directory
**Default:** `$XDG_CONFIG_HOME/kongctl`

```bash
export KONGCTL_CONFIG_DIR=/path/to/kongctl-config
kongctl login
```

#### KONGCTL_DEFAULT_PROFILE

**Type:** String
**Description:** Default profile to use when `--profile` flag is not specified
**Default:** `default`

```bash
export KONGCTL_DEFAULT_PROFILE=production
kongctl get apis
# Uses production profile automatically
```

### Region and endpoint variables

#### KONGCTL_DEFAULT_REGION

**Type:** String
**Description:** Default {{site.konnect_short_name}} region
**Values:** `us`, `eu`, `au`
**Default:** `us`

```bash
export KONGCTL_DEFAULT_REGION=eu
kongctl login
# Authenticates to EU region by default
```

### Output and formatting variables

#### KONGCTL_NO_COLOR

**Type:** Boolean
**Description:** Disable colored output
**Values:** `1`, `true`, or any non-empty value enables
**Default:** Not set (colors enabled)

```bash
export KONGCTL_NO_COLOR=1
kongctl get apis
# Output without ANSI color codes
```

Useful for:
* CI/CD logs
* Piping to files
* Systems without ANSI color support

#### KONGCTL_OUTPUT_FORMAT

**Type:** String
**Description:** Default output format for commands
**Values:** `table`, `json`, `yaml`
**Default:** `table`

```bash
export KONGCTL_OUTPUT_FORMAT=json
kongctl get apis
# Always outputs JSON unless overridden with --output
```

### Debugging variables

#### KONGCTL_DEBUG

**Type:** Boolean
**Description:** Enable debug logging
**Values:** `1`, `true`, or any non-empty value enables
**Default:** Not set

```bash
export KONGCTL_DEBUG=1
kongctl get apis
```

Debug output includes:
* API requests and responses
* Authentication details
* Configuration loading
* Error stack traces

#### KONGCTL_LOG_LEVEL

**Type:** String
**Description:** Logging level
**Values:** `debug`, `info`, `warn`, `error`
**Default:** `info`

```bash
export KONGCTL_LOG_LEVEL=debug
kongctl plan -f config/
```

### HTTP settings

#### KONGCTL_HTTP_TIMEOUT

**Type:** Integer (seconds)
**Description:** HTTP request timeout
**Default:** `30`

```bash
export KONGCTL_HTTP_TIMEOUT=60
kongctl get apis
```

#### KONGCTL_HTTP_RETRY

**Type:** Integer
**Description:** Number of retry attempts for failed requests
**Default:** `3`

```bash
export KONGCTL_HTTP_RETRY=5
kongctl apply -f config/
```

#### HTTPS_PROXY / HTTP_PROXY

**Type:** String (URL)
**Description:** Proxy server for HTTP/HTTPS requests
**Default:** Not set

```bash
export HTTPS_PROXY=http://proxy.example.com:8080
export HTTP_PROXY=http://proxy.example.com:8080
kongctl get apis
```

## Configuration examples

### Development environment

```yaml
# ~/.config/kongctl/config.yaml
default:
  output: json
  konnect:
    region: us
  log-level: debug
```

```bash
kongctl login
kongctl get apis
```

### Multiple environments

```yaml
# ~/.config/kongctl/config.yaml
development:
  output: json
  konnect:
    region: us

staging:
  output: yaml
  konnect:
    region: eu

production:
  output: json
  konnect:
    region: us
```

```bash
# Authenticate each profile
kongctl login --profile development
kongctl login --profile staging
kongctl login --profile production

# Use different profiles
kongctl get apis --profile development
kongctl apply -f config.yaml --profile production
```

### CI/CD authentication

**GitHub Actions**:

```yaml
- name: Deploy to Konnect
  env:
    KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
    KONGCTL_DEFAULT_REGION: us
    KONGCTL_NO_COLOR: 1
    KONGCTL_LOG_LEVEL: info
  run: |
    kongctl plan -f config/ --output-file plan.json
    kongctl apply --plan plan.json
```

**GitLab CI**:

```yaml
deploy:
  script:
    - kongctl apply -f config/
  variables:
    KONGCTL_DEFAULT_KONNECT_PAT: $KONNECT_PAT
    KONGCTL_DEFAULT_REGION: eu
    KONGCTL_NO_COLOR: "1"
    KONGCTL_OUTPUT_FORMAT: json
```

**Jenkins**:

```bash
environment {
    KONGCTL_DEFAULT_KONNECT_PAT = credentials('konnect-pat')
    KONGCTL_DEFAULT_REGION = 'us'
    KONGCTL_NO_COLOR = '1'
}

stages {
    stage('Deploy') {
        steps {
            sh 'kongctl apply -f config/'
        }
    }
}
```

**Docker**:

```bash
docker run \
  -e KONGCTL_DEFAULT_KONNECT_PAT="$KONNECT_PAT" \
  -e KONGCTL_DEFAULT_REGION=us \
  -e KONGCTL_NO_COLOR=1 \
  -v $(pwd)/config:/config \
  kong/kongctl:latest \
  apply -f /config
```

### Multi-region deployment

```yaml
# ~/.config/kongctl/config.yaml
us-production:
  konnect:
    region: us

eu-production:
  konnect:
    region: eu

au-production:
  konnect:
    region: au
```

```bash
# Authenticate each region
kongctl login --profile us-production
kongctl login --profile eu-production
kongctl login --profile au-production

# Deploy to all regions
kongctl apply -f config/ --profile us-production
kongctl apply -f config/ --profile eu-production
kongctl apply -f config/ --profile au-production
```

## Advanced configuration

### Color themes

Customize the color theme for interactive experiences like `kongctl kai` or `kongctl view`:

```yaml
default:
  color-theme: tokyo_night
```

Available themes are from [`bubbletint`](https://github.com/lrstanley/bubbletint). The default `kong` theme matches Kong brand colors.

### Custom base URL

For testing or custom deployments, override the base URL:

```yaml
testing:
  konnect:
    base-url: https://test.api.konghq.com
```

The `base-url` setting always takes precedence over `region`.

### Configuration precedence example

```yaml
# config.yaml
default:
  output: table
  konnect:
    region: us
```

```bash
# Environment overrides config
export KONGCTL_DEFAULT_OUTPUT=json
export KONGCTL_DEFAULT_KONNECT_REGION=eu

# Flag overrides everything
kongctl get apis --output yaml --region au
# Result: Uses yaml output and au region
```

Precedence order:
1. `--output yaml --region au` (flags - highest)
2. `KONGCTL_DEFAULT_OUTPUT=json` and `KONGCTL_DEFAULT_KONNECT_REGION=eu` (env vars)
3. `output: table` and `region: us` (config file)
4. Built-in defaults (lowest)

## Regions

By default, kongctl uses the `us` region. You can switch regions using:

```bash
# Set region via flag
kongctl get apis --region eu

# Set region in config
# config.yaml:
#   default:
#     konnect:
#       region: eu

# Set region via environment variable
export KONGCTL_DEFAULT_KONNECT_REGION=au
```

**List available regions**:

```bash
kongctl get regions
```

See the [{{site.konnect_short_name}} geos documentation](/konnect-platform/geos/) for current region availability.

## Troubleshooting

### View current configuration

```bash
# Show effective configuration
kongctl config show

# Show configuration for specific profile
kongctl config show --profile production
```

### Authentication issues

```bash
# Check authentication status
kongctl get me

# Re-authenticate
kongctl logout
kongctl login

# Test with explicit PAT
kongctl get apis --pat kpat_your-token-here
```

### Debug configuration loading

```bash
# Enable debug logging to see config loading
export KONGCTL_DEBUG=1
kongctl get apis
```

### Clear all configuration

```bash
# Remove configuration directory
rm -rf ~/.config/kongctl/

# Re-initialize
kongctl login
```

## Related resources

* [Get started with kongctl](/kongctl/get-started/)
* [Declarative configuration guide](/kongctl/declarative/)
* [CI/CD integration](/kongctl/cicd/)
* [Authentication guide](/kongctl/authentication/)
