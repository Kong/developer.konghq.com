---
title: 'Azure Functions'
name: 'Azure Functions'

content_type: plugin

publisher: kong-inc
description: 'Invoke and manage Azure functions from {{site.base_gateway}}'


products:
    - gateway

works_on:
    - on-prem
    - konnect


topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: azure-functions.png

categories:
  - serverless

search_aliases:
  - azure-functions

tags:
  - serverless
  - azure

related_resources:
  - text: Use an Azure Function through {{site.base_gateway}}
    url: /how-to/use-an-azure-function-through-gateway/

min_version:
  gateway: '1.0'
---

This plugin invokes [Azure Functions](https://azure.microsoft.com/en-us/services/functions/).
It can be used in combination with other [request plugins](/plugins/?terms=request) 
to secure, manage, or extend the function.
