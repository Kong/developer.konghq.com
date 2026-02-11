---
title: 'TrendAI API Security'
name: 'TrendAI API Security'

content_type: plugin

publisher: trendai
description: 'Strengthen your overall API Security with TrendAI Vision One'

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

The TrendAI API Security plugin delivers risk visibility for your {{site.base_gateway}}s and protects their cloud-hosted infrastructure through TrendAI Vision One [Cloud Risk Management](https://www.trendmicro.com/en_us/business/products/hybrid-cloud/cloud-risk-management.html) and [Container Security](https://www.trendmicro.com/en_us/business/products/hybrid-cloud/cloud-one-container-image-security.html).

This plugin connects your Kong environment to the [TrendAI Vision One]() platform, and is intended for TrendAI Vision One customers.

Key benefits include:
* Discovery and risk assessment of {{site.base_gateway}}s and their associated APIs, including checks for misconfiguration, authentication status, zombie APIs, and internet exposure.
* {{site.base_gateway}} mapping within your cloud infrastructure to show its location and surrounding context. 
This visibility helps you understand the cloud environment around {{site.base_gateway}} and protect the underlying cloud infrastructure. 
Requires TrendAI Vision One Cloud Risk Management and Container Security licenses.

## How it works

When enabled, the TrendAI API Security plugin periodically collects {{site.base_gateway}} configuration data from Routes, Services, Upstreams, Targets, and Plugins, and sends it to the TrendAI Vision One backend for analysis and cloud infrastructure mapping.
TrendAI Vision One then generates an API Inventory, detects API Gateway misconfigurations, and correlates the {{site.base_gateway}} data plane node’s compute instance with your cloud infrastructure through TrendAI Vision One Cloud Risk Management.

## Install the TrendAI API Security plugin

You can install the TrendAI API Security plugin by downloading and mounting its files on {{site.base_gateway}}’s system.

### Prerequisites

- A TrendAI Vision one account.
- Add [{{site.base_gateway}} as a Third Party Integration in TrendAI Vision One](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-kong-gateway).
Download the plugin gzip file and retrieve the required FQDN and token values. These values will be configured in the plugin to ensure data is sent back to the correct TrendAI Vision One account.

### Installation steps

The following instructions use LuaRocks to install the plugin from a source archive. For other installation methods, please refer to the documentation from [Kong](https://docs.konghq.com/gateway/latest/plugin-development/distribution/#install-the-plugin).

1. Transfer the plugin source code to your {{site.base_gateway}} node.
1. Ensure [LuaRocks](https://luarocks.org/) is installed in your {{site.base_gateway}} node.
1. Unzip the plugin contents and change your terminal's current directory to the extracted archive where the `.rockspec` file is located:

    ```bash
    cd trend-micro-kong-plugin-aps-main
    ```

5. Run the following command to install the plugin:

    ```bash
    luarocks make
    ```

Next, refer to the installation instructions based on your deployment type.

{% navtabs 'install-options' %}
{% navtab "Konnect" %}

{{site.konnect_short_name}} requires the custom plugin’s `schema.lua` file to create a plugin entry in the plugin catalog for your control plane.
Upload the `schema.lua` file from the downloaded zip file to create a configurable entity in {{site.konnect_short_name}}:

1. In the {{site.konnect_short_name}} menu, click **API Gateway**.
1. Click a control plane.
1. From the control plane's menu, click **Plugins**.
1. Click **New Plugin**.
1. Click **Custom Plugin**.
1. Upload the `schema.lua` file for your plugin.
1. Check that your file displays correctly in the preview, then click **Save**.
1. After uploading a schema to {{site.konnect_short_name}}, upload the `schema.lua` and `handler.lua` files from the downloaded zip archive to each {{site.base_gateway}} data plane node. 
   If a data plane node doesn’t have these files, the plugin won’t be able to run on that node.
1. Follow the Dockerfile installation instructions on this page (switch tabs) to get your plugin set up on each node. 

You can now configure this custom plugin like any other plugin in {{site.konnect_short_name}}.

{% endnavtab %}
{% navtab "Docker/Kubernetes" %}

If you are running {{site.base_gateway}} on Docker or Kubernetes, the plugin needs to be installed inside the {{site.base_gateway}} container.
Copy or mount the plugin’s source code into the container. Here’s an example Dockerfile that shows how to mount your plugin in the {{site.base_gateway}} image:

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

{% endnavtab %}
{% endnavtabs %}

## Configuring the plugin

To enable and configure the plugin, see the [plugin setup example](/plugins/trend-micro-kong-plugin-aps/examples/enable-trendai-plugin/).