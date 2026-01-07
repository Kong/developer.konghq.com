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
        Before you begin, you must get the following credentials from Google Cloud:

        - **Service Account Key**: A JSON key file for a service account with Vertex AI permissions
        - **Project ID**: Your Google Cloud project identifier
        - **Location ID**: The region where your Vertex AI endpoint is deployed (for example, `us-central1`)
        - **API Endpoint**: The Vertex AI API endpoint URL (typically `https://{location}-aiplatform.googleapis.com`)

        Export these values as environment variables:
        ```sh
        export GEMINI_API_KEY="<your_gemini_api_key>"
        export GCP_PROJECT_ID="<your-gemini-project-id>"
        export GEMINI_LOCATION_ID="<your-gemini-location_id>"
        export GEMINI_API_ENDPOINT="<your_gemini_api_endpoint>"
        ```
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

The AI Proxy Advanced plugin supports Google's Gemini models and works with the Google Generative AI SDK. This configuration allows you to use the standard Gemini SDK while Kong AI Gateway handles authentication with GCP service accounts and manages the connection to Vertex AI endpoints.

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
              name: gemini-3-pro-preview
              options:
                anthropic_version: vertex-2023-10-16
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

## Test with Google Generative AI SDK

Create a test script that uses the Google Generative AI SDK. The script initializes a client with a dummy API key because Kong AI Gateway handles authentication, then sends a generation request through the gateway:
```py
cat << 'EOF' > gemini.py
#!/usr/bin/env python3
"""Test Google Generative AI SDK via Kong AI Gateway"""
from google import genai

BASE_URL = "http://localhost:8000/gemini"

def gemini_chat():
    """Basic chat using Gemini API through Kong AI Gateway"""

    try:
        print(f"Connecting to: {BASE_URL}")

        client = genai.Client(
            api_key="dummy-key",  # Replace with your Gemini API Key
            vertexai=False
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

The response contains the model's generated text. The SDK handles the request formatting and response parsing, while Kong AI Gateway manages authentication and proxying to Vertex AI.