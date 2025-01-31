---
title: "Managing {{site.base_gateway}} configuration"

description: |
  The {{site.base_gateway}} configuration file `kong.conf` can be used to configure individual properties of your Kong instance.
content_type: reference
layout: reference
no_version: true

products:
   - gateway

related_resources:
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/
  - text: "{{site.base_gateway}} CLI"
    url: /gateway/cli/

works_on:
   - on-prem
   - konnect
---

{{site.base_gateway}} comes with the configuration file `kong.conf`. You can use this file to configure individual properties of a {{site.base_gateway}} instance. By default, this file is located at `/etc/kong/kong.conf.default`.

In {{site.konnect_short_name}}, you can use `kong.conf` to manage the configuration of each data place instance, however, you can't edit the properties of the control plane.

For all available parameters in `kong.conf`, see the [Configuration Parameter reference](/gateway/configuration/). 

## Configuring {{site.base_gateway}}

To configure {{site.base_gateway}}, make a copy of the default configuration file: 

```bash
cp /etc/kong/kong.conf.default /etc/kong/kong.conf
```

The file contains {{site.base_gateway}} configuration properties and documentation. 
For any value that remains commented out in `kong.conf`, {{site.base_gateway}} will use the default settings.

For example, here's the entry for `log_level`: 

```bash
#log_level = notice              # Log level of the Nginx server. Logs are
                                 # found at `<prefix>/logs/error.log`.
```

To configure a property, uncomment it and modify the value:

```bash
log_level = warn
```

You can set boolean values as `on`/`off` or `true`/`false`. For example:

```bash
dns_no_sync = off
```

## Environment variables

{{site.base_gateway}} can be fully configured with environment variables. 

[All parameters defined in `kong.conf`](/gateway/configuration/) 
can be managed via environment variables.
When loading properties from `kong.conf`, {{site.base_gateway}} checks existing
environment variables first.

To override a setting using an environment variable, declare an environment
variable with the name of the setting, prefixed with `KONG_`.

For example, to override the `log_level` parameter:

```
log_level = debug # in kong.conf
```

Set `KONG_LOG_LEVEL` as an environment variable:

```bash
export KONG_LOG_LEVEL=error
```

## Using the Kong CLI to manage kong.conf

There are a few useful [Kong CLI](/gateway/cli/) commands for managing `kong.conf` files:
* `kong prepare`: Prepare the Kong prefix folder with all of its subfolders and files, including `kong.conf`.
* `kong check`: Check if a Kong configuration file is valid.
* `kong start`: Start Kong in the configured prefix directory.
* `kong reload` and `kong restart`: Reload a container, or restart an instance of Kong, and apply configuration.

### Updating Kong configuration

{{site.base_gateway}} reads the Kong configuration file when you run `kong start` or `kong prepare`.
Load the configuration file using one of these CLI commands:

1. Run `kong prepare` to prepare the Kong prefix folder with all of its subfolders and files. 
2. Run either `kong reload` or `kong restart` to reboot the {{site.base_gateway}} instance and apply configuration.

### Verifying configuration

To verify that your configuration is valid, use the `kong check` command. 
The `kong check` command evaluates all parameters you currently have set, 
including any set as [environment variables](#environment-variables).

For example:

```bash
kong check /etc/kong/kong.conf
```
If your configuration is valid, you will see the following response:

```bash
configuration at /etc/kong/kong.conf is valid
```

### Debug mode

You can use the {{site.base_gateway}} CLI in debug mode to output all configuration properties, 
including all properties set using environment variables.

Pass the `--vv` flag to any Kong CLI command to enable verbose debug mode:

```bash
kong prepare --conf /etc/kong/kong.conf --vv
```

This will output your entire Kong configuration to the terminal. 
For example, here's a snippet:
```
2025/01/31 06:52:01 [debug] reading environment variables
2025/01/31 06:52:01 [debug] KONG_DATABASE ENV found with "off"
2025/01/31 06:52:01 [debug] KONG_PREFIX ENV found with "/usr/local/kong"
2025/01/31 06:52:01 [debug] KONG_ROLE ENV found with "data_plane"
[...]
```
{:.no-copy-code}

## Using a custom file path

By default, {{site.base_gateway}} looks for `kong.conf` in two
locations: `/etc/kong/kong.conf` and `/etc/kong.conf`.

You can override this behavior by specifying a custom path for your
configuration file using the `-c / --conf` argument with most Kong CLI commands:

```bash
kong prepare --conf /path/to/kong.conf
```

