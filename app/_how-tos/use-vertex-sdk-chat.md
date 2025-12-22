---
title: Use Google Generative AI SDK for Vertex AI service chats with Kong AI Gateway
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Vertex AI Authentication
    url: https://cloud.google.com/vertex-ai/docs/authentication

description: "Configure the AI Proxy Advanced plugin to authenticate with Google's Gemini API using GCP service account credentials and test with the native Vertex AI request format."

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
  q: How do I configure Gemini authentication with a service account in Kong AI Gateway?
  a: Configure the AI Proxy Advanced plugin with the Gemini provider and set gcp_use_service_account to true with your service account JSON credentials.

tools:
  - deck

prereqs:
  inline:
    - title: Vertex AI
      include_content: prereqs/vertex-ai
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

## Configure the AI Proxy Advanced plugin

The AI Proxy Advanced plugin supports Google's Vertex AI models with service account authentication. This configuration allows you to route requests in Vertex AI's native format through Kong Gateway. The plugin handles authentication with GCP, manages the connection to Vertex AI endpoints, and proxies requests without modifying the Gemini-specific request structure.

Apply the plugin configuration with your GCP service account credentials:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      service: gemini-service
      config:
        llm_format: gemini
        genai_category: text/generation
        targets:
          - route_type: llm/v1/chat
            logging:
              log_payloads: false
              log_statistics: true
            model:
              provider: gemini
              name: gemini-2.0-flash-exp
              options:
                gemini:
                  api_endpoint: ${gcp_api_endpoint}
                  project_id: ${gcp_project_id}
                  location_id: ${gcp_location_id}
            auth:
              allow_override: false
              gcp_use_service_account: true
              gcp_service_account_json: ${gcp_service_account_json}
variables:
  gcp_api_endpoint:
    value: $GCP_API_ENDPOINT
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
  gcp_location_id:
    value: $GCP_LOCATION_ID
{% endentity_examples %}

## Create Python script

Create a test script that sends a request using Vertex AI's native API format. The script constructs the Vertex AI endpoint URL with your project ID and location, then sends a properly formatted request with the required `role` and `parts` structure:

```py
cat << 'EOF' > vertex.py
#!/usr/bin/env python3
"""Test Vertex AI format via Kong Gateway"""
import requests
import os

BASE_URL = "http://localhost:8000/gemini"
PROJECT_ID = os.getenv("DECK_GCP_PROJECT_ID")
LOCATION = os.getenv("DECK_GCP_LOCATION_ID")

def vertex_chat():
    """Basic chat using Vertex AI format via Kong Gateway"""

    url = f"{BASE_URL}/v1/projects/{PROJECT_ID}/locations/{LOCATION}/publishers/google/models/gemini-2.0-flash-exp:generateContent"

    headers = {
        "Content-Type": "application/json"
    }

    payload = {
        "contents": [{
            "role": "user",
            "parts": [{"text": "Hello! How are you?"}]
        }]
    }

    response = requests.post(url, headers=headers, json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

if __name__ == "__main__":
    vertex_chat()
EOF
```

## Validate the configuration

Now, let's run the script we created in the previous step:
```sh
python3 vertex.py
```

Expected output:

```text
Status: 200
Response: {'candidates': [{'content': {'role': 'model', 'parts': [{'text': "I am doing well, thank you for asking! As a large language model, I don't experience feelings or emotions, but I am ready and available to assist you. How can I help you today?\n"}]}, 'finishReason': 'STOP', 'avgLogprobs': -0.21152742518935091}], 'usageMetadata': {'promptTokenCount': 6, 'candidatesTokenCount': 43, 'totalTokenCount': 49}, 'modelVersion': 'gemini-2.0-flash-exp'}
```

You should see that the response includes the model's generated text in the `candidates[0].content.parts[0].text` field, along with usage metadata showing token counts for the request and response.