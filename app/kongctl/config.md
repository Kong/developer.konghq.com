---
title: Configuration of kongctl
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

related_resources:
  - text: kongctl authentication reference 
    url: /kongctl/authentication/
  - text: kongctl declarative configuration reference 
    url: /kongctl/declarative/
  - text: kongctl authorization options
    url: /kongctl/authentication/
  - text: Managing {{site.konnect_short_name}} resources declaratively
    url: /kongctl/declarative/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: Using kongctl and decK for full API platform management
    url: /kongctl/kongctl-and-deck/
---

kongctl provides a flexible system for configuring the CLI behavior which allows
you to customize behavior for different machines, {{site.konnect_short_name}} organizations, 
environments, and automation pipelines.

{:.info}
> **Note:** The term _configuration_ in this document describes altering of the behavior of the CLI itself, 
> not to be confused with _declarative configuration_ used to manage the state of 
> {{site.konnect_short_name}} resources. 
> For declarative configuration, see the [declarative configuration guide](/kongctl/declarative/).


## Profiles

kongctl supports named collections of configuration values, which are called _profiles_. 
You can use profiles to separate configurations for any purpose you need. Common usage 
includes different organizations, regions, or machines.

{:.info}
> Using profiles is optional. If no profile is specified, a built-in profile named `default` is applied.

**Sample configuration snippet**:

```yaml
my-profile:     # profile name
  output: json  # configuration value
  konnect:       
    region: us  # configuration names can be nested
```

Each kongctl invocation uses a single profile to determine which configuration values to apply. 
You can specify the profile in different ways:

```bash
# No profile specified, the 'default' profile is implied
kongctl get apis

# Specify profile with flag
kongctl get apis --profile production

# Specify profile with environment variable
KONGCTL_PROFILE=production kongctl get apis

# Export a profile via environment variable
export KONGCTL_PROFILE=production
# Uses the production profile 
kongctl get apis
# Also uses the production profile 
kongcll apply -f config.yaml
```

## Configuration values  

All kongctl configuration values can be loaded via flags, environment variables, 
or the configuration file. This allows you to set defaults in files while 
overriding them as needed for specific commands or environments.

All configuration values are specified via a _path_. The path to a particular configuration value 
is provided in the usage text of the command. For example, the {{site.konnect_short_name}} 
region configuration value is shown in the help text as:

```text
--region string     Konnect region identifier (for example "eu")... 
                          - Config path: [ konnect.region ]
```
{:.no-copy-code}

This shows that you can specify a region with the `--region` flag, 
but you can also set it in the configuration file or via environment variables based on the config path.

In the configuration file, this value would be set under the profile name with the following YAML syntax:

```yaml
default:
  konnect:
    region: eu
```

## Environment variables

When values are loaded via environment variables, the variable names 
must start with the `KONGCTL_` prefix, then the desired profile, 
and finally the config path in uppercase with underscores instead of dots. 

For example, to set the same region value for the default profiles, 
set the following environment variable:

```text
KONGCTL_DEFAULT_KONNECT_REGION=eu
```


## Configuration file

By default kongctl reads configurations from a file located at 
`$XDG_CONFIG_HOME/kongctl/config.yaml` and falls back to 
`~/.config/kongctl/config.yaml` if `XDG_CONFIG_HOME` is not set.

You can specify a different configuration file via the `--config-file flag`:

```bash
--config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
```
{:.no-copy-code}

### Precedence

kongctl configuration values are loaded in the following precedence (highest to lowest):

1. **Command-line flags**: Explicit flags like `--pat`, `--region`, `--output`
2. **Environment variables**: `KONGCTL_<PROFILE>_<CONFIG_PATH>` variables
3. **Configuration file**: Values in `config.yaml`
4. **Default values**: Built-in defaults
