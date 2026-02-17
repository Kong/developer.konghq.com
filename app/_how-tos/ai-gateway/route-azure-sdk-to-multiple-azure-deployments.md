---
title: Route Azure AI SDK requests to Azure OpenAI deployments
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: "AI Proxy Advanced: Dynamic Azure deployments"
    url: /plugins/ai-proxy-advanced/examples/sdk-azure-one-route/

permalink: /how-to/route-azure-sdk-to-multiple-azure-deployments

description: Configure a single route that dynamically maps OpenAI SDK requests to different Azure OpenAI deployments based on the URL path.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - azure
  - ai-sdks

tldr:
  q: How do I route Azure AI SDK requests to different Azure OpenAI deployments through a single Kong route?
  a: Create a route with a regex path that captures the deployment name, then use the `$(uri_captures)` template variable in AI Proxy Advanced to set the Azure deployment ID dynamically.

tools:
  - deck

prereqs:
  inline:
    - title: Azure OpenAI service
      include_content: prereqs/azure-ai
      icon_url: /assets/icons/azure.svg
    - title: Python
      include_content: prereqs/python
      icon_url: /assets/icons/python.svg
    - title: OpenAI SDK
      include_content: prereqs/openai-sdk
      icon_url: /assets/icons/openai.svg
  entities:
    services:
      - azure-openai-service
    routes:
      - azure-chat-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

The [Azure OpenAI SDK](https://github.com/openai/openai-python#microsoft-azure-openai) can connect to [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/chatgpt) through Kong AI Gateway. With Azure, the `model` parameter in SDK calls maps to a deployment name on your Azure instance. The SDK constructs request URLs in the format `https://{azure_instance}.openai.azure.com/openai/deployments/{azure_deployment_id}/chat/completions`. When the SDK sends a request to `/openai/deployments/gpt-4o/chat/completions`, the route captures `gpt-4o` into the `azure_deployment` named group.

Instead of creating a separate route for each deployment, you can configure a single route with a regex path that captures the deployment name from the URL. [AI Proxy Advanced](/plugins/ai-proxy-advanced/) reads the captured value through a [template variable](/plugins/ai-proxy-advanced/#dynamic-model-and-options-from-request-parameters) and uses it as the Azure deployment ID.

## Configure the AI Proxy Advanced plugin

First, let's configure [AI Proxy Advanced](/plugins/ai-proxy-advanced/) to read the deployment name from the captured path segment. The [`$(uri_captures.azure_deployment)` template](/plugins/ai-proxy-advanced/#templating) variable resolves at request time:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      route: azure-chat-route
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: api-key
              header_value: ${azure_openai_key}
            model:
              provider: azure
              name: "$(uri_captures.azure_deployment)"
              options:
                azure_instance: ${azure_instance}
                azure_deployment_id: "$(uri_captures.azure_deployment)"
variables:
  azure_openai_key:
    value: $AZURE_OPENAI_KEY
  azure_instance:
    value: $AZURE_INSTANCE
{% endentity_examples %}

## Validate

Now, let's create a test script that sends requests to different Azure deployments through the same Kong route. The `AzureOpenAI` client constructs URLs with `/openai/deployments/{model}/chat/completions`, which matches the route regex. The `model` parameter determines which deployment receives the request:
```bash
cat <<EOF > test_azure_deployments.py
from openai import AzureOpenAI

client = AzureOpenAI(
    api_key="test",
    azure_endpoint="http://localhost:8000",
    api_version="2025-01-01-preview"
)

for model in ["gpt-4o", "gpt-4.1-mini"]:
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Requested: {model}, Got: {response.model}")
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }
```bash
cat <<EOF > test_azure_deployments.py
from openai import AzureOpenAI
import os

client = AzureOpenAI(
    api_key="test",
    azure_endpoint=os.environ['KONNECT_PROXY_URL'],
    api_version="2025-01-01-preview"
)

for model in ["gpt-4o", "gpt-4.1-mini"]:
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Requested: {model}, Got: {response.model}")
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

Run the script:
```bash
python test_azure_deployments.py
```

You should see each request routed to the corresponding Azure deployment, confirming that a single Kong route handles multiple deployments dynamically:

```text
Requested: gpt-4o, Got: gpt-4o-2024-11-20
Requested: gpt-4.1-mini, Got: gpt-4.1-mini-2025-04-14
```
{:.no-copy-code}