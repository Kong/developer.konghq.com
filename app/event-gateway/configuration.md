---
title: "{{site.event_gateway_short}} configuration reference"
content_type: reference
layout: reference

plugin_schema: true

no_edit_link: true

description: |
  Reference for {{ site.event_gateway }} configuration parameters.

products:
    - event-gateway

min_version:
    event-gateway: '1.0'

versioned: true

breadcrumbs:
  - /event-gateway/
---

Reference for {{site.event_gateway}} data plane configuration parameters.

You can configure a {{site.event_gateway}} data plane in one of the following ways:
* Pass a configuration file in YAML format
* Use environment variables

{{site.event_gateway_short}} reads settings in the following order of precedence:
1. Environment variables
2. YAML configuration file
3. Default parameters

_[This is a total guess, need to verify]_

## Using a configuration file

To configure {{site.event_gateway_short}}, create a configuration file named `some-filename.yaml`.

_[To do - need more info]_

## Using environment variables

All configuration parameters for {{site.event_gateway_short}} data planes can be managed via environment variables.

To configure a setting using an environment variable, declare an environment variable with the name of the setting. 
* Parameters specific to your data plane, such as observability and debugging, must be prefixed with `KEG__`
* Parameters that define the connection between the data plane and the control plane must be prefixed with `KEG__KONNECT__` or `KONNECT_`

See each [configuration parameter](#configuration-parameters) for the specific environment variable that you need to set.

For example, to set the log level to error, you would set the following:

```sh
export KEG__OBSERVABILITY__LOG_FLAGS=error
```

## Applying configuration

_[To do - need more info]_

## Configuration parameters

{% event_gateway_conf %}
