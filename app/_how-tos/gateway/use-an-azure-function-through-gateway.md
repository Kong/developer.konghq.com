---
title: Use an Azure Function through {{site.base_gateway}}
permalink: /how-to/use-an-azure-function-through-gateway/
content_type: how_to
description: Learn how to configure the Azure Functions plugin to invoke an Azure Function in a Route.
products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - azure-functions

entities: 
  - plugin

tags:
    - azure
    - serverless

tldr:
    q: How can I use an Azure Function in {{site.base_gateway}}?
    a: Create an [Azure Function](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview) and deploy it to Azure, then configure the [Azure Functions plugin](/plugins/azure-functions/) with the Function App name, the Azure Function name, and the Function App API key.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Azure Function
      content: |
        This tutorial requires an [Azure Function](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview). In this example, we'll use the quickstart function provided by Azure. 
        
        If you don't have an existing Azure Function, you can create one by following the steps in [Create your first function](https://learn.microsoft.com/en-us/azure/azure-functions/functions-get-started?pivots=programming-language-csharp#create-your-first-function).

        Once your function is created, save the following values to your environment:
        * The Function App name. It's generated automatically when [deploying the quickstart function](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-azure-developer-cli?pivots=programming-language-csharp&tabs=linux%2Cget%2Cbash%2Cpowershell#deploy-to-azure-1).
        * The function name, `httpget` in this example.
        * The API key to use to access the function. You can find it in your Function App details in the Azure portal, under **Functions** > **App keys**.

        {% env_variables %}
        DECK_APP_NAME: 'YOUR FUNCTION APP NAME'
        DECK_FUNCTION_NAME: 'httpget'
        DECK_FUNCTION_APP_KEY: 'YOUR FUNCTION APP API KEY'
        section: prereqs
        {% endenv_variables %}
      icon_url: /assets/icons/azure.svg 

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Enable the Azure Functions plugin

To invoke your Azure Function through your Route, enable the [Azure Functions plugin](/plugins/azure-functions/) on the Route with the configuration parameters for your [function](#azure-function):

{% entity_examples %}
entities:
  plugins:
  - route: example-route
    name: azure-functions
    config:
      appname: ${app}
      functionname: ${func}
      apikey: ${key}
variables:
  app:
    value: $APP_NAME
  func:
    value: $FUNCTION_NAME
  key:
    value: $FUNCTION_APP_KEY
{% endentity_examples %}

## Validate

Send a request to the Route we created to validate:
<!--vale off -->
{% validation request-check %}
url: '/anything'
status_code: 200
display_headers: true
{% endvalidation %}
<!--vale on -->

With the quickstart function, you should get the following response:
```sh
Hello, World.
```
{:.no-copy-code}