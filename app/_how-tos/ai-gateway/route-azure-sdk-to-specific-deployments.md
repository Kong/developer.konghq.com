---
title: Route Azure OpenAI SDK requests to specific deployments with multiple routes
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: "AI Proxy Advanced: Multi-deployment chat routing example"
    url: /plugins/ai-proxy-advanced/examples/sdk-multiple-azure-deployments/

permalink: /how-to/route-azure-sdk-to-specific-deployments

description: Configure separate {{site.base_gateway}} Routes that map to specific Azure OpenAI deployments, each with its own AI Proxy Advanced configuration.

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
  q: How do I map Azure OpenAI SDK requests to specific deployments using separate {{site.base_gateway}} Routes?
  a: Create a Route for each Azure deployment with a path that matches the SDK's URL pattern, then configure AI Proxy Advanced on each Route with the corresponding deployment ID. The SDK switches between deployments by changing the base URL.

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
      - azure-gpt-4o
      - azure-gpt-4-1-mini

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

The [Azure OpenAI SDK](https://github.com/openai/openai-python#microsoft-azure-openai) constructs request URLs in the format `https://{azure_instance}.openai.azure.com/openai/deployments/{deployment_id}/chat/completions`. Each deployment has its own URL path.

You can map each deployment to a separate {{site.base_gateway}} Route with its own [AI Proxy Advanced](/plugins/ai-proxy-advanced/) configuration. The SDK switches between deployments by pointing `azure_endpoint` at {{site.base_gateway}} and changing the `model` parameter. {{site.base_gateway}} matches the request to the correct Route and forwards it to the corresponding Azure deployment. When the SDK sends a request with `model="gpt-4o"`, the `AzureOpenAI` client constructs the path `/openai/deployments/gpt-4o/chat/completions`, which matches the first Route. Requests with `model="gpt-4.1-mini"` match the second Route.

This approach gives you explicit control over each deployment's configuration, such as different auth keys, model options, or logging settings per deployment.

## Configure AI Proxy Advanced for the GPT-4o Route

Configure [AI Proxy Advanced](/plugins/ai-proxy-advanced/) on the `azure-gpt-4o` Route to target the `gpt-4o` deployment:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      route: azure-gpt-4o
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: api-key
              header_value: ${azure_openai_key}
            model:
              provider: azure
              name: gpt-4o
              options:
                azure_instance: ${azure_instance}
                azure_deployment_id: gpt-4o
variables:
  azure_openai_key:
    value: $AZURE_OPENAI_API_KEY
  azure_instance:
    value: $AZURE_INSTANCE_NAME
{% endentity_examples %}

## Configure AI Proxy Advanced for the GPT-4.1-mini Route

Configure [AI Proxy Advanced](/plugins/ai-proxy-advanced/) on the `azure-gpt-4-1-mini` Route to target the `gpt-4.1-mini` deployment:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      route: azure-gpt-4-1-mini
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: api-key
              header_value: ${azure_openai_key}
            model:
              provider: azure
              name: gpt-4.1-mini
              options:
                azure_instance: ${azure_instance}
                azure_deployment_id: gpt-4.1-mini
variables:
  azure_openai_key:
    value: $AZURE_OPENAI_API_KEY
  azure_instance:
    value: $AZURE_INSTANCE_NAME
{% endentity_examples %}

## Validate

Create a test script that sends requests to both deployments through {{site.base_gateway}}. The `AzureOpenAI` client constructs the correct URL path for each deployment based on the `model` parameter:
```bash
cat <<EOF > test_azure_multi_route.py
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
cat <<EOF > test_azure_multi_route.py
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
python test_azure_multi_route.py
```

You should see each request routed to the corresponding Azure deployment, confirming that each Route maps to a different model.