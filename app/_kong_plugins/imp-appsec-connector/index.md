---
title: Imperva API Security 
name: Imperva API Security 

publisher: imperva
support_url: https://www.imperva.com/support/technical-support/

content_type: plugin

description: Integrate {{site.base_gateway}} with Imperva API Security to discover, monitor, and protect APIs

products:
    - gateway

works_on:
    - on-prem
    - konnect

tags:
  - monitoring

third_party: true

icon: imperva.png

search_aliases:
  - imp-appsec-connector

related_resources:
  - text: Imperva documentation
    url: https://docs.imperva.com/

min_version:
  gateway: '3.0'
---

The Imperva API Security plugin connects {{site.base_gateway}} with the Imperva API Security service, providing continuous discovery and monitoring of APIs exposed by {{site.base_gateway}}.
This enables security teams to protect business applications and data against unauthorized access. 

The plugin operates with a very low CPU and memory footprint, avoiding any negative impact on the inline performance of the Gateway or your applications.

## How the Imperva plugin works

Here's how the Imperva API Security plugin works:
1. The plugin captures API calls with request/response payloads and sends them to the Imperva API Security service for inspection. 
2. API calls are copied and streamed through {{site.base_gateway}}. 
3. You provide the API Security receiver service [destination address](/plugins/imp-appsec-connector/reference/#schema--config-destination-addr) and [port](/plugins/imp-appsec-connector/reference/#schema--config-destination-port) though the plugin's configuration, so the API data is kept under the control of the application owner.
Additional [parameters](/plugins/imp-appsec-connector/reference/) are used to control how the API captures are sent. 

## Install the Imperva plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="imp-appsec-connector" %}

{:.info}
> If you are using the [{{site.kic_product_name}}](/kubernetes-ingress-controller/), the installation is slightly different. 
> Review the [custom plugin docs for the {{site.kic_product_name}}](/kubernetes-ingress-controller/custom-plugins/).
