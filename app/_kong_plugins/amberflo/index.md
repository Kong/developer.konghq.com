---
title: 'Amberflo.io API Metering'
name: 'Amberflo.io API Metering'

content_type: plugin

publisher: amberflo
description: 'API usage metering and usage-based billing'

products:
    - gateway

works_on:
    - on-prem

# on_prem:
#   - hybrid
#   - db-less
#   - traditional
# konnect_deployments:
#   - hybrid
#   - cloud-gateways
#   - serverless

third_party: true

support_url: https://github.com/amberflo/kong-plugin-amberflo/issues

source_code_url: https://github.com/amberflo/kong-plugin-amberflo

license_url: https://github.com/amberflo/kong-plugin-amberflo/blob/main/LICENSE

privacy_policy_url: https://www.amberflo.io/privacy-policy

terms_of_service_url: https://www.amberflo.io/terms-of-use

icon: amberflo.png

search_aliases:
  - amberflo.io
  - kong-plugin-amberflow

min_version:
  gateway: '3.0'
---


The Amberflo plugin allows you to understand customer [API usage](https://www.amberflo.io/products/metering) and implement [usage-based price & billing](https://www.amberflo.io/products/billing) by metering the requests with [Amberflo.io](https://amberflo.io).

It supports high-volume HTTP(S) usage without adding latency.

[Amberflo](https://amberflo.io) is the simplest way to integrate metering into your application. [Sign up for free](https://ui.amberflo.io/) to get started.

## How it works

This plugin intercepts requests, detects which customer is making them, generates a meter event, and sends it to Amberflo.

Customer detection occurs via inspection of the request headers. 
You can configure {{site.base_gateway}} to inject the `customerId` as a header before this plugin runs. 
For example, if you use the [Key Authentication](/plugins/key-auth/) plugin, this occurs automatically.

To avoid impacting the performance of your Gateway, the plugin batches the meter records and sends them asynchronously to Amberflo.

## Install the Amberflo plugin

This is a server plugin implemented in Go. 

1. To install the plugin, you need to make the binary available to {{site.base_gateway}}:

   ```sh
   GOBIN=/tmp go install github.com/amberflo/kong-plugin-amberflo@latest
   mv /tmp/kong-plugin-amberflo /usr/local/bin/amberflo
   ```

2. Register the plugin in your `kong.conf` file:

   ```
   plugins = bundled,amberflo

   pluginserver_names = amberflo

   pluginserver_amberflo_start_cmd = /usr/local/bin/amberflo
   pluginserver_amberflo_query_cmd = /usr/local/bin/amberflo -dump
   ```

3. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```
