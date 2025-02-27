---
title: 'Request Termination'
name: 'Request Termination'

content_type: plugin

publisher: kong-inc
description: 'Terminates all requests with a specific response'

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
icon: request-termination.png

categories:
  - traffic-control

search_aliases:
  - request-termination

related_resources:
  - text: Allow clients to choose their authentication methods and prevent unauthorized access
    url: /how-to/allow-multiple-authentication/
---

This plugin terminates incoming requests with a specified status code and message.
This can be used to temporarily stop traffic on a Gateway Service or a Route, or even block a Consumer. 

This plugin can also be used for debugging, as described in the [`config.echo` parameter](/plugins/request-termination/reference/#schema--config-echo).

Once this plugin is enabled, every request within the configured scope will be immediately terminated with the configured status code and message.

## Request termination priority

This plugin has a priority of `2`, which is the lowest priority of all plugins except Post-Function. This means it will execute after all other plugins have been applied. 

The Request Termination plugin will not execute if the [Forward Proxy plugin](/plugins/forward-proxy/) is enabled. 
This is because the Forward Proxy plugin has a higher priority, and when it executes, the request is forwarded according to that plugin's configuration. 

To change the execution order, configure [dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering).

## Example use cases

The following table lists some common use cases for the Request Termination plugin:

| If you want to... | Then see... |
|-------------------|-------------|
| Temporarily disable a Service <br><br> _For example, if the Service is under maintenance_ | [Block requests on Service](/plugins/request-termination/examples/block-requests-with-error?format=deck&target=service) |
| Temporarily disable a Route <br><br> _For example, if the rest of the Service is up and running, but a particular endpoint must be disabled_ | [Block requests on Route](/plugins/request-termination/examples/block-requests-with-error?format=deck&target=route) |
| Temporarily disable a Consumer <br><br> _For example, if you have a Consumer with excessive consumption_ | [Block requests by Consumer](/plugins/request-termination/examples/block-requests-with-error?format=deck&target=consumer) |
| Block anonymous access with multiple authentication plugins in a logical `OR` setup |[Allow clients to choose their authentication methods and prevent unauthorized access](/how-to/allow-multiple-authentication/) |
| Debug erroneous requests in live systems using `config.echo` | [Debug requests by echoing response back to client](/plugins/request-termination/examples/echo-response-to-client?format=deck&target=consumer) |

