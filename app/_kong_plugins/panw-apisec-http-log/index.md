---
title: 'Palo Alto Networks API Security'
name: 'Palo Alto Networks API Security'

content_type: plugin

publisher: palo-alto-networks
description: 'Enhance your API security by integrating your {{site.base_gateway}} with Cortex API Security'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.4'

third_party: true
support_url: 'https://support.paloaltonetworks.com/Support/Index'

icon: panw-apisec-http-log.png

search_aliases:
  - panw-apisec-http-log

tags:
  - security
  - logging

related_resources:
  - text: Cortex API Security - Kong plugin documentation
    url: https://docs-cortex.paloaltonetworks.com/r/Cortex-CLOUD/Cortex-Cloud-Runtime-Security-Documentation/Ingest-Kong?tocId=9b7Q1OcnzkkC41gRI008uQ
---

Enhance your API security by integrating your {{site.base_gateway}} with Cortex API Security. 
This is achieved using a dedicated HTTP Log plugin (`panw-apisec-http-log`) designed for Kong. 
This plugin enables seamless ingestion of API traffic data from your {{site.base_gateway}} directly into Cortex API Security.

By leveraging this integration, you can apply comprehensive security measures, including:
* OWASP Top 10 threat detection
* Bot protection
* Access control enforcement
* and more

## How the Palo Alto Networks API Security plugin works

When the Palo Alto Networks API Security plugin is enabled on a {{site.base_gateway}} Service or Route,
it intercepts and processes API requests and their corresponding responses. 

For each transaction, the plugin collects relevant data, such as:
* Request and response bodies
* HTTP headers
* Query parameters
* Status codes

This collected data is then sent to a designated Palo Alto Networks API Security collector endpoint. 

The plugin doesn't modify the request and response in any way.

## Install the Palo Alto Networks API Security plugin

You can install the Palo Alto Networks API Security plugin by downloading and mounting its file on {{site.base_gateway}}'s system.

### Prerequisites

[Create a Kong collector on Cortex](https://docs-cortex.paloaltonetworks.com/r/Cortex-CLOUD/Cortex-Cloud-Runtime-Security-Documentation/Ingest-Kong?tocId=9b7Q1OcnzkkC41gRI008uQ). 
Use the download link provided below the collector’s API key to download plugin `gzip` file.
The file includes the `handler.lua`, `utils.lua`, and `schema.lua` files that make up the custom plugin.

### Install

{% navtabs "install" %}
{% navtab "Docker" %}

Add the plugin to your {{site.base_gateway}} instance by mounting the plugin directory, 
adding it to the Lua package path variable, and adding the plugin name to the `plugins` field when starting the container:

```sh
-v ".plugin_directory/kong:/tmp/custom_plugins/kong" \
-e "KONG_LUA_PACKAGE_PATH=/tmp/custom_plugins/?.lua" \
-e "KONG_PLUGINS=bundled, panw-apisec-http-log
```

You may want to adjust the size of the Nginx body buffer, which is used by {{site.base_gateway}} internally.
This size sets the upper limit on the amount of HTTP body bytes that can be mirrored by the plugin. 
By default, this value is 8192 bytes (8 KB). 

To change it, adjust the [Nginx body buffer size](/gateway/configuration/#nginx-http-client-body-buffer-size) setting:

```sh
-e "KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16k"
```

{% endnavtab %}
{% navtab "kong.conf" %}

1. Update your loaded plugins list in {{site.base_gateway}}.
In your [`kong.conf`](/gateway/configuration/), append `panw-apisec-http-log` to the `plugins` field. Make sure the field isn't commented out:

   ```
   plugins = bundled,panw-apisec-http-log
   ```

1. You may want to adjust the size of the Nginx body buffer, which is used by {{site.base_gateway}} internally.
This size sets the upper limit on the amount of HTTP body bytes that can be mirrored by the plugin. 
By default, this value is 8192 bytes (8 KB). 

   To change it, adjust the [`nginx_http_client_body_buffer_size`](/gateway/configuration/#nginx-http-client-body-buffer-size) setting in `kong.conf`:
 
   ```
   nginx_http_client_body_buffer_size = 16k
   ```

1. Restart {{site.base_gateway}} to apply changes:

   ```sh
   kong restart
   ```

{% endnavtab %}
{% endnavtabs %}

{:.info}
> If you are using the [{{site.kic_product_name}}](/kubernetes-ingress-controller/), the installation is slightly different. 
> Review the [custom plugin docs for the {{site.kic_product_name}}](/kubernetes-ingress-controller/custom-plugins/).

