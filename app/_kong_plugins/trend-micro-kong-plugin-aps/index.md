---
title: 'TrendAI API Security'
name: 'TrendAI API Security'

content_type: plugin

publisher: trendai
description: 'Risk visibility for your Kong Gateways and protection ofr their cloud-hosted infrastructure through TrendAI Vision One Cloud Risk Management and Container Security'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.4'

tags:
  - security

search_aliases:
  - trend micro
  - trend ai
  - trend-micro-kong-plugin-aps
  
third_party: true
# source_code_url: ''
support_url: 'https://docs.trendmicro.com/en-us/documentation/'

icon: trend-micro-kong-plugin-aps.svg

related_resources:
  - text: Trend Vision One API documentation
    url: https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-apis
---

Strengthen your overall API Security with TrendAI Vision One.
The TrendAI API Security plugin delivers risk visibility for your Kong Gateways and protects their cloud-hosted infrastructure through TrendAI Vision One Cloud Risk Management and Container Security. 

This plugin connects your Kong environment to the TrendAI Vision One platform, and is intended for TrendAI Vision One customers.

Key benefits include:
* Discovery and risk assessment of Kong Gateways and their associated APIs, including checks for misconfiguration, authentication status, zombie APIs, and internet exposure.
* Kong Gateway mapping within your cloud infrastructure to show its location and surrounding context. This visibility helps you understand the cloud environment around Kong Gateway and protect the underlying cloud infrastructure. Requires TrendAI Vision One Cloud Risk Management and Container Security licenses.

## How it works

When enabled, the plugin periodically collects Kong Gateway configuration data from Routes, Services, Upstreams, Targets, and Plugins, and sends it to the TrendAI Vision One backend for analysis and cloud infrastructure mapping. 
TrendAI Vision One then generates an API Inventory, detects API Gateway misconfigurations, and correlates the Kong data plane node’s compute instance with your cloud infrastructure through TrendAI Vision One Cloud Risk Management.

## Install the TrendAI API Security plugin

### Prerequisites
- A TrendAI Vision one account

### Installation steps

You can install the TrendAI API Security plugin by downloading and mounting its file on Kong Gateway’s system.

Add [Kong Gateway as a Third Party Integration in TrendAI Vision One](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-kong-gateway).
Follow the linked documentation to download the plugin gzip file and retrieve the required FQDN and token values. These values are configured in the plugin to ensure data is sent back to the correct TrendAI Vision One account.


## Installation

The following instructions use LuaRocks to install the plugin from a source archive. For other installation methods, please refer to the documentation from [Kong](https://docs.konghq.com/gateway/latest/plugin-development/distribution/#install-the-plugin).

1. Download the plugin code from this repository as a zip file.
2. Transfer the plugin source code to your Kong Gateway node.
3. Ensure [LuaRocks](https://luarocks.org/) is installed in your Kong Gateway node.
4. Unzip the plugin contents and change your terminal's current directory to the extracted archive where the `.rockspec` file is located.

```bash
cd trend-micro-kong-plugin-aps-main
```

5. Run the following command to install the plugin

```bash
luarocks make
```

Please refer to the section based on your Kong Deployment Type:

### DockerFile/Kubernetes

If you are running Kong Gateway on Docker or Kubernetes, the plugin needs to be installed inside the Kong Gateway container.
Copy or mount the plugin’s source code into the container. Here’s an example Dockerfile that shows how to mount your plugin in the Kong Gateway image:

```yaml
FROM kong/kong-gateway:latest
# Ensure any patching steps are executed as root user
USER root
# Add plugin to the image
COPY kong-plugin-trend/kong/plugins/trend-micro-kong-plugin-aps /usr/local/share/lua/5.1/kong/plugins/trend-micro-kong-plugin-aps
ENV KONG_PLUGINS=bundled,trend-micro-kong-plugin-aps
# Ensure kong user is selected for image execution
USER kong
# Run kong
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]
```

### Kong Konnect™

:warning: Custom plugins are [not supported](https://docs.konghq.com/konnect/gateway-manager/plugins/add-custom-plugin/) in [Dedicated Cloud Gateways](https://docs.konghq.com/konnect/gateway-manager/dedicated-cloud-gateways/). Dedicated Cloud Gateways are data plane nodes that are fully managed by Kong in Konnect.

#### Add plugin to a control plane

Kong Konnect™ requires the custom plugin’s schema.lua file to create a plugin entry in the plugin catalog for your control plane.
Upload the `schema.lua` file from the downloaded zip file to create a configurable entity in Konnect:

1. From the Gateway Manager, open a control plane.
2. Open Plugins from the side navigation, then click Add Plugin.
3. Open the Custom Plugins tab, then click Create on the Custom Plugin tile.
4. Upload the schema.lua file for your plugin.
5. Check that your file displays correctly in the preview, then click Save.

#### Upload files to data plane nodes

After uploading a schema to Konnect, upload the `schema.lua` and `handler.lua` file from the downloaded zip archive to each Kong Gateway data plane node.
If a data plane node doesn’t have these files, the plugin won’t be able to run on that node.
Follow the [DockerFile](#dockerfilekubernetes) installation instructions to get your plugin set up on each node. You can now configure this custom plugin like any other plugin in Konnect.

## Configuration

### Setup the Trend API Key and Endpoint URL

The Trend Vision One for Kong Gateway plugin relies on a Trend Vison One API key and Endpoint URL. Ensure you have copied these parameters from the Kong Gateway Third-Party Integrations page in Trend Vision One.
It is recommended that you store and manage this key in a vault. See [Secrets Management](https://docs.konghq.com/gateway/latest/kong-enterprise/secrets-management/) for more details. The configuration examples presented below use the Environment [Variables Vault](https://docs.konghq.com/gateway/latest/kong-enterprise/secrets-management/backends/env/), however this is not recommended for a production environment.
The API key is stored as an environment variable on the Kong Gateway node:

```bash
export TREND_API_KEY={api_key}
```