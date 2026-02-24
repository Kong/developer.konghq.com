---
title: Use Google Generative AI SDK for Vertex AI service chats with {{site.ai_gateway}}
permalink: /how-to/use-vertex-sdk-chat/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
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
  - ai-sdks

tldr:
  q: How do I use Vertex AI's native format with {{site.ai_gateway}}?
  a: Configure the AI Proxy Advanced plugin with `llm_format` set to `gemini`, then send requests using Vertex AI's native API format with the contents array structure.

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

automated_tests: false
---

## Configure the AI Proxy Advanced plugin

The AI Proxy Advanced plugin supports Google's Vertex AI models with service account authentication. This configuration allows you to route requests in Vertex AI's native format through {{site.ai_gateway}}. The plugin handles authentication with GCP, manages the connection to Vertex AI endpoints, and proxies requests without modifying the Gemini-specific request structure.

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
              gcp_service_account_json: |-
                ${gcp_service_account_json}
variables:
  gcp_api_endpoint:
    value: $GCP_API_ENDPOINT
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
    literal_block: true
  gcp_location_id:
    value: $GCP_LOCATION_ID
{% endentity_examples %}

## Create Python script

Create a test script that sends a request using Vertex AI's native API format. The script constructs the Vertex AI endpoint URL with your project ID and location, then sends a properly formatted request:

```py
cat << 'EOF' > vertex.py
#!/usr/bin/env python3
import os
from google import genai
import sys
import time
import threading

def spinner():
    chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
    idx = 0
    while not stop_spinner:
        sys.stdout.write(f'\r{chars[idx % len(chars)]} Generating response...')
        sys.stdout.flush()
        idx += 1
        time.sleep(0.1)
    sys.stdout.write('\r' + ' ' * 30 + '\r')
    sys.stdout.flush()

client = genai.Client(
    vertexai=True,
    project=os.environ.get("DECK_GCP_PROJECT_ID", "gcp-sdet-test"),
    location=os.environ.get("DECK_GCP_LOCATION_ID", "us-central1"),
    http_options={
        "base_url": "http://localhost:8000/gemini"
    }
)

stop_spinner = False
spinner_thread = threading.Thread(target=spinner)
spinner_thread.start()

try:
    response = client.models.generate_content(
        model="gemini-2.0-flash-exp",
        contents="Hello! Say hello back to me!"
    )
    stop_spinner = True
    spinner_thread.join()
    print(f"Model: {response.model_version}")
    print(response.text)
except Exception as e:
    stop_spinner = True
    spinner_thread.join()
    print(f"Error: {e}")
EOF
```

## Validate the configuration

Now, let's run the script we created in the previous step:

```sh
python3 vertex.py
```

Expected output:

```text
Hello there!
```