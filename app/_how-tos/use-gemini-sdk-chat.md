---
title: Use Google Generative AI SDK for Gemini AI service chats with Kong AI Gateway
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Google Generative AI SDK
    url: https://ai.google.dev/gemini-api/docs/sdks

description: "Configure the AI Proxy Advanced plugin for Gemini and test with the Google Generative AI SDK using the standard Gemini API format."

products:
  - gateway
  - ai-gateway

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

tldr:
  q: How do I use the Google Generative AI SDK with Kong AI Gateway?
  a: Configure the AI Proxy Advanced plugin with `llm_format` set to `gemini`, then use the Google Generative AI SDK to send requests through Kong AI Gateway.

tools:
  - deck

prereqs:
  inline:
    - title: Gemini AI
      content: |
        Before you begin, you must get the Gemini API key from Google Cloud:

        1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
        2. Select or create a project.
        3. Enable the **Generative Language API**:
           - Navigate to **APIs & Services > Library**.
           - Search for "Generative Language API".
           - Click **Enable**.
        4. Create an API key:
           - Navigate to **APIs & Services > Credentials**.
           - Click **Create Credentials > API Key**.
           - Copy the generated API key.


        Export the API key as an environment variable:
        ```sh
        export DECK_GEMINI_API_KEY="<your_gemini_api_key>"
        ```
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
    value: $GCP_API_KEY
{% endentity_examples %}

## Test with Google Generative AI SDK

Create a test script that uses the Google Generative AI SDK. The script initializes a client with a dummy API key because Kong AI Gateway handles authentication, then sends a generation request through the gateway:

```py
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

The response contains the model's generated text. The SDK handles the request formatting and response parsing, while Kong AI Gateway manages authentication and proxying to Vertex AI.