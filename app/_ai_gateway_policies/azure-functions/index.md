---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
tools:
  - konnect-api
  - kongctl
description: Invoke and manage Azure functions from {{site.ai_gateway_name}}

tags:
  - serverless
  - azure
search_aliases:
  - azure-functions
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
---

The Azure Functions [AI Policy](/ai-gateway/entities/ai-policy/) invokes [Azure Functions](https://azure.microsoft.com/en-us/services/functions/) from {{site.ai_gateway}}.
Instead of forwarding a request to an upstream, the policy sends the request to your Azure function and returns the function's response to the client.
Use it to expose an existing Azure function through a {{site.ai_gateway}} endpoint, so clients call one address and the function stays behind the gateway.

## How does the Azure Functions Policy work?

When a request reaches an entity that has the policy attached, the policy builds the function URL and calls it:

```text
https://APP_NAME.HOST_DOMAIN/ROUTE_PREFIX/FUNCTION_NAME
```

The following settings build the URL:

* `config.appname`: The name of your Azure app.
* `config.hostdomain`: The domain where the function resides. Defaults to `azurewebsites.net`.
* `config.routeprefix`: The route prefix. Defaults to `api`.
* `config.functionname`: The name of the function to invoke.

The policy forwards the HTTP method, query string, headers, and body of the client request to the function.
It also sets the following headers when you configure the matching setting:

* `x-functions-key`: Set from `config.apikey`.
* `x-functions-clientid`: Set from `config.clientid`.

The policy returns the status code, headers, and body from the function to the client.
The entity that the policy is attached to never sends the request to its upstream.

The following example invokes a function named `my-function` in the `my-app` Azure app:

{% entity_example %}
type: policy
data:
  name: azure-function-invoke
  display_name: Invoke Azure Function
  type: azure-functions
  config:
    appname: my-app
    hostdomain: azurewebsites.net
    functionname: my-function
    apikey: $AZURE_API_KEY
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Use the policy in {{site.ai_gateway}}

The Azure Functions Policy attaches to an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), because {{site.ai_gateway}} has no Gateway Services or Routes.
The entity provides the route that clients call, and the policy answers the request.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

* **The upstream doesn't receives traffic:** The policy answers the request itself.
  An AI Model still requires an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) target, and clients must still send the `model` field that the AI Model route matches on.
  {{site.ai_gateway}} doesn't send the request to the provider.
* **{{site.ai_gateway}} changes the request body first:** Before the policy runs, {{site.ai_gateway}} processes the request for the AI Model.
  For example, the `model` field in the body becomes the provider model name configured on the target, so the function receives that value instead of the AI Model name.
* **Scope:** Attach the policy to an AI Model, AI Agent, AI MCP Server, or AI Consumer.
  The policy doesn't support [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) scope.

{:.warning}
> Don't apply the Azure Functions Policy globally.
> A global policy answers every request on the data plane, so AI Models, AI Agents, or AI MCP Servers don't receive traffic.

## Configuration notes

* Set `config.routeprefix` to at least one character.
  Keep the default `api`, or set the prefix that your function app uses.
* Store `config.apikey` and `config.clientid` as secret references.
  Konnect returns a literal value in API responses as plain text.
* Make sure the data plane can reach the Azure function.
  When the policy can't connect, clients receive a `500` response with the message `An unexpected error occurred`, and the cause appears in the data plane log.
