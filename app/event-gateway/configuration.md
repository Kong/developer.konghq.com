---
title: "{{site.event_gateway_short}} configuration reference"
content_type: reference
layout: reference

plugin_schema: true

no_edit_link: true

description: |
  Reference for {{ site.event_gateway }} data plane configuration parameters.

products:
    - event-gateway

min_version:
    event-gateway: '1.0'

versioned: true

breadcrumbs:
  - /event-gateway/
---

You can configure {{site.event_gateway}} data plane nodes at start time. 
When starting a data plane, pass parameters to it to specify how to connect to the control plane, configure observability, logging levels, and so on.

## Applying configuration

You can configure a {{site.event_gateway}} data plane at start time by passing environment variables or a YAML configuration file.

{{site.event_gateway_short}} reads settings for a data plane node in the following order of precedence:
1. Environment variables
2. YAML configuration file
3. Default parameters

{:.info}
> **Note**: Configuration can only be applied at data plane node startup. 
If you need to adjust any configuration, launch a new data plane, or stop the data plane and relaunch it with the new file or environment variables.

{% navtabs 'config' %}
{% navtab "Using environment variables" %}

All configuration parameters for {{site.event_gateway_short}} data planes can be managed via environment variables.

To configure a setting using an environment variable, declare an environment variable with the name of the setting. 
* Parameters specific to your data plane, such as observability and debugging, must be prefixed with `KEG__`
* Parameters that define the connection between the data plane and the control plane must be prefixed with `KEG__KONNECT__` or `KONNECT_`

See each [configuration parameter](#configuration-parameters) for the specific environment variable that you need to set.

For example, to set the log level to error, you would set the following during launch, adding `KEG__OBSERVABILITY__LOG_FLAGS` to the default parameters:

```sh
docker run -d \
-e "KONNECT_REGION=us" \
-e "KONNECT_DOMAIN=konghq.com" \
-e "KONNECT_GATEWAY_CLUSTER_ID=your-gateway-id" \
-e "KONNECT_CLIENT_CERT=example-cert" \
-e "KONNECT_CLIENT_KEY=example-key" \
-e "KEG__OBSERVABILITY__LOG_FLAGS=error" \
-p 19092-19101:19092-19101 \
kong/kong-event-gateway:latest
```
{% endnavtab %}
{% navtab "Using a configuration file" %}

{:.info}
> **Note:** Using a local config file is intended for internal development and testing purposes only.

To configure {{site.event_gateway_short}}, you can create a configuration file in YAML format.

For example, here's a basic configuration file that adds a log level setting to the default data plane node settings:
```yaml
cat <<EOF > bootstrap.yaml
konnect:
  region: us
  domain: konghq.com
  gateway_cluster_id: example-gateway-uuid
  client_cert: |
    example-cert
  client_key: |
    example-key
observability:
  log_flags: error
EOF
```

To apply the file, mount the file to the container and pass the `--bootstrap` flag with the run command. 
For example:

```sh
docker run \
  -v /host/path:/container/path \
  kong/kong-event-gateway:latest \
  --bootstrap bootstrap.yaml
```
{% endnavtab %}
{% endnavtabs %}

## Configuration parameters

{% event_gateway_conf %}
