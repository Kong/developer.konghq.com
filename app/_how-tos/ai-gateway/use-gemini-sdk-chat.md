---
title: Use Google Generative AI SDK for Gemini AI service chats with {{site.ai_gateway}}
permalink: /how-to/use-gemini-sdk-chat/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Google Generative AI SDK
    url: https://ai.google.dev/gemini-api/docs/sdks

description: "Configure the AI Proxy plugin for Gemini and test with the Google Generative AI SDK using the standard Gemini API format."

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.10'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - gemini

tldr:
  q: How do I use the Google Generative AI SDK with {{site.ai_gateway}}?
  a: Configure the AI Proxy Advanced plugin with `llm_format` set to `gemini`, then use the Google Generative AI SDK to send requests through {{site.ai_gateway}}.

tools:
  - deck

prereqs:
  inline:
    - title: Gemini AI
      include_content: prereqs/gemini
      icon_url: /assets/icons/gcp.svg
    - title: Python
      include_content: prereqs/python
      icon_url: /assets/icons/python.svg
    - title: Google Generative AI SDK
      content: |
        Install the Google Generative AI SDK:
        ```sh
        pip install google-generativeai
        ```
      icon_url: /assets/icons/gcp.svg
  entities:
    services:
      - gemini-service
    routes:
      - gemini-route

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

## Configure the AI Proxy plugin

The AI Proxy plugin supports Google's Gemini models and works with the Google Generative AI SDK. This configuration allows you to use the standard Gemini SDK. Apply the plugin configuration with your GCP service account credentials:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      service: gemini-service
      config:
        route_type: llm/v1/chat
        llm_format: gemini
        auth:
            param_name: key
            param_value: ${gcp_api_key}
            param_location: query
        model:
            provider: gemini
            name: gemini-2.0-flash-exp
variables:
  gcp_api_key:
    value: $GEMINI_API_KEY
{% endentity_examples %}

## Test with Google Generative AI SDK

Create a test script that uses the Google Generative AI SDK. The script initializes a client with a dummy API key because {{site.ai_gateway}} handles authentication, then sends a generation request through the gateway:

```py
cat << 'EOF' > gemini.py
#!/usr/bin/env python3
import os
from google import genai

BASE_URL = "http://localhost:8000/gemini"

def gemini_chat():

    try:
        print(f"Connecting to: {BASE_URL}")

        client = genai.Client(
            api_key=os.environ.get("DECK_GEMINI_API_KEY"),
            vertexai=False,
            http_options={
                "base_url": BASE_URL
            }
        )

        print("Sending message...")
        response = client.models.generate_content(
            model="gemini-2.0-flash-exp",
            contents="Hello! How are you?"
        )

        print(f"Response: {response.text}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    gemini_chat()
EOF
```

Run the script:
```sh
python3 gemini.py
```

Expected output:

```text
Connecting to: http://localhost:8000/gemini
Sending message...
Response: Hello! I'm doing well, thank you for asking. As a large language model, I don't experience feelings or emotions in the way humans do, but I'm functioning properly and ready to assist you. How can I help you today?
```