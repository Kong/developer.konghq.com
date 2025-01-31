---
title: "Managing {{site.base_gateway}} configuration"

description: |
  The {{site.base_gateway}} configuration file `kong.conf` can be used to configure individual properties of your {{site.base_gateway}} instance.
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

{{site.base_gateway}} comes with the configuration file `kong.conf`. 
You can use this file to configure individual properties of a {{site.base_gateway}} instance. 
By default, this file is located at `/etc/kong/kong.conf.default`.

In {{site.konnect_short_name}}, you can use `kong.conf` to manage the configuration of each data place instance, 
however, you can't edit the properties of the control plane.

For all available configuration parameters in `kong.conf`, see the [Configuration Parameter reference](/gateway/configuration/). 

## Configuring {{site.base_gateway}}

To configure {{site.base_gateway}}, make a rename the default configuration file: 

```bash
cp /etc/kong/kong.conf.default /etc/kong/kong.conf
```

The file contains {{site.base_gateway}} configuration properties and documentation. 
Commented out parameters in `kong.conf`, {{site.base_gateway}} will use the default settings, until they are uncommented and modified. 
In this example, the `log_level` value is commented out, by default {{site.base_gateawy}} sets the `log_level` to `notice`.

```bash
#log_level = notice              # Log level of the Nginx server. Logs are
                                 # found at `<prefix>/logs/error.log`.
```

To configure a property, uncomment it and modify the value:

```bash
log_level = warn
```

## Applying configuration

Apply changes to a configuration using the `kong restart` command, availble from the [Kong CLI](/gateway/cli).
This restarts the {{site.base_gateway}} instance and applies configuration.

{:.info}
> If you're running {{site.base_gateway}} in a quickstart Docker container for testing, update 
{{site.base_gateway}} configuration using [environment variables](#environment-variables)
and use `kong reload` instead of `kong restart`.

## Environment variables

[All parameters defined in `kong.conf`](/gateway/configuration/) 
can be managed via environment variables.
When loading properties from `kong.conf`, {{site.base_gateway}} checks existing
environment variables first.

To configure a setting using an environment variable, declare an environment
variable with the name of the setting, prefixed with `KONG_`. This will override the existing value in `kong.conf`.

For example, to override the `log_level` parameter:

```
log_level = debug # in kong.conf
```

Set `KONG_LOG_LEVEL` as an environment variable, then restart or reload {{site.base_gateway}}.

```bash
export KONG_LOG_LEVEL=error
```

## Using a custom file path

By default, {{site.base_gateway}} looks for `kong.conf` in two
locations: `/etc/kong/kong.conf` and `/etc/kong.conf`.

You can override this behavior by specifying a custom path for your
configuration file using the `-c / --conf` argument with most Kong CLI commands:

```bash
kong start --conf /path/to/kong.conf
```


## Verifying configuration

To verify that your configuration is valid, use `kong check` command. 
The `kong check` command evaluates all parameters set in `kong.conf`
including any set as [environment variables](#environment-variables).

For example:

```bash
kong check /etc/kong/kong.conf
```
If your configuration is valid, you will see the following response:

```bash
configuration at /etc/kong/kong.conf is valid
```

## Debugging the configuration file

You can use the Kong CLI in debug mode to output all configuration properties, 
including all properties set using environment variables.

Pass the `--vv` flag to any Kong CLI command to enable verbose debug mode:

```bash
kong prepare --conf /etc/kong/kong.conf --vv
```

This will output your entire Kong configuration to the terminal. 
For example, running `kong prepare` with the `--vv` flag will output this:
```sh
2025/01/31 06:52:01 [debug] reading environment variables
2025/01/31 06:52:01 [debug] KONG_DATABASE ENV found with "off"
2025/01/31 06:52:01 [debug] KONG_PREFIX ENV found with "/usr/local/kong"
2025/01/31 06:52:01 [debug] KONG_ROLE ENV found with "data_plane"
[...]
```
{:.no-copy-code}


