---
title: Stream responses from Vertex AI through Kong AI Gateway
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Vertex AI Streaming
    url: https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini#stream

description: "Configure the AI Proxy Advanced plugin to stream responses from Google's Vertex AI using the native streamGenerateContent endpoint format."

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
  - streaming

tldr:
  q: How do I stream responses from Vertex AI through Kong AI Gateway?
  a: Configure the AI Proxy Advanced plugin with `llm_format` set to `gemini`, then send requests to the `:streamGenerateContent` endpoint. The response returns as a JSON array containing incremental text chunks.

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
    - title: Python requests library
      content: |
        Install the requests library:
        ```sh
        pip install requests
        ```
      icon_url: /assets/icons/python.svg
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

First, let's configure the AI Proxy Advanced plugin to support streaming responses from Vertex AI models. When proxied through this configuration, the Vertex AI model returns response tokens incrementally as the model generates them, reducing perceived latency for longer outputs. The plugin proxies requests to Vertex AI's `:streamGenerateContent` endpoint without modifying the response format.

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

## Create Python streaming script

Create a script that sends requests to Vertex AI's streaming endpoint. The `:streamGenerateContent` suffix signals that the response should return as incremental chunks rather than a single complete generation.

Vertex AI's streaming format returns a JSON array where each element contains a chunk of the generated response. The entire array arrives in a single HTTP response body, not as server-sent events or newline-delimited JSON.

The script includes two optional flags for debugging and inspection:
- `--raw` displays the complete JSON structure returned by Vertex AI before extracting text
- `--chunks` shows metadata for each chunk, including finish reasons and token counts

```py
cat << 'EOF' > vertex_stream.py
#!/usr/bin/env python3
import requests
import json
import sys
import os

BASE_URL = "http://localhost:8000/gemini"
PROJECT_ID = os.getenv("DECK_GCP_PROJECT_ID")
LOCATION = os.getenv("DECK_GCP_LOCATION_ID", "us-central1")
MODEL = "gemini-2.0-flash-exp"

def vertex_stream(show_raw=False, show_chunks=False):
    """Stream responses from Vertex AI through Kong Gateway"""

    url = f"{BASE_URL}/v1/projects/{PROJECT_ID}/locations/{LOCATION}/publishers/google/models/{MODEL}:streamGenerateContent"

    headers = {
        "Content-Type": "application/json",
    }

    payload = {
        "contents": [{
            "role": "user",
            "parts": [{"text": "Explain quantum entanglement in one paragraph"}]
        }]
    }

    print(f"Connecting to: {url}\n")

    response = requests.post(url, headers=headers, json=payload, stream=True)

    if response.status_code != 200:
        print(f"Error {response.status_code}: {response.text}")
        return

    raw_data = response.text.strip()

    if show_raw:
        try:
            parsed = json.loads(raw_data)
            print("Raw JSON structure:")
            print(json.dumps(parsed, indent=2))
            print("\n" + "="*80 + "\n")
        except json.JSONDecodeError:
            print("Raw response (invalid JSON):")
            print(raw_data)
            print("\n" + "="*80 + "\n")

    if raw_data.startswith('['):
        raw_data = raw_data[1:]
    if raw_data.endswith(']'):
        raw_data = raw_data[:-1]

    objects = []
    current = ""
    depth = 0

    for char in raw_data:
        current += char
        if char == '{':
            depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0 and current.strip():
                objects.append(current.strip().lstrip(',').strip())
                current = ""

    chunk_num = 0
    for obj_str in objects:
        if not obj_str:
            continue
        try:
            data = json.loads(obj_str)
            if "candidates" in data:
                chunk_num += 1
                for candidate in data["candidates"]:
                    content = candidate.get("content", {})
                    finish_reason = candidate.get("finishReason")

                    if show_chunks:
                        print(f"\n--- Chunk {chunk_num} ---")
                        if finish_reason:
                            print(f"Finish reason: {finish_reason}")
                        usage = data.get("usageMetadata", {})
                        if usage.get("totalTokenCount"):
                            print(f"Total tokens: {usage.get('totalTokenCount')}")
                        print("Text: ", end="")

                    for part in content.get("parts", []):
                        if "text" in part:
                            print(part["text"], end="", flush=True)

                    if show_chunks:
                        print()
        except json.JSONDecodeError as e:
            print(f"\nJSON parse error: {e}")
            print(f"Failed object: {obj_str[:100]}")

    if not show_chunks:
        print()

if __name__ == "__main__":
    show_raw = "--raw" in sys.argv
    show_chunks = "--chunks" in sys.argv
    vertex_stream(show_raw, show_chunks)
EOF
```

## Response format

The streaming endpoint returns a JSON array. Each element contains a chunk with this structure:

```json
[
  {
    "candidates": [{
      "content": {
        "role": "model",
        "parts": [{"text": "1"}]
      }
    }],
    "usageMetadata": {
      "trafficType": "ON_DEMAND"
    },
    "modelVersion": "gemini-2.0-flash-exp"
  },
  {
    "candidates": [{
      "content": {
        "role": "model",
        "parts": [{"text": ", 2, 3, 4, 5\n"}]
      },
      "finishReason": "STOP"
    }],
    "usageMetadata": {
      "promptTokenCount": 4,
      "candidatesTokenCount": 14,
      "totalTokenCount": 18
    }
  }
]
```

The script extracts the `text` field from each `parts` array and prints it incrementally. The final element includes `finishReason` and complete token usage statistics.

## Validate the configuration

Run the script to verify streaming responses:

```sh
python3 vertex_stream.py
```

Expected output shows text appearing as the model generates it:

```text
Connecting to: http://localhost:8000/gemini/v1/projects/your-project/locations/us-central1/publishers/google/models/gemini-2.0-flash-exp:streamGenerateContent

Quantum entanglement is a bizarre phenomenon where two or more particles become linked together in such a way that they share the same fate, no matter how far apart they are. Measuring the state of one entangled particle instantly influences the state of the other, even across vast distances, seemingly violating the classical concept of locality. This "spooky action at a distance" means knowing the property of one particle immediately reveals the corresponding property of its entangled partner, even before any measurement is made on it directly.
```

### Display chunk metadata

You can use the `--chunks` flag to inspect individual chunks with their metadata:
```sh
python3 vertex_stream.py --chunks
```

Expected output:
```text
Connecting to: http://localhost:8000/gemini/v1/projects/your-project/locations/us-central1/publishers/google/models/gemini-2.0-flash-exp:streamGenerateContent

--- Chunk 1 ---
Text: Quantum entanglement is a peculiar phenomenon

--- Chunk 2 ---
Finish reason: STOP
Total tokens: 87
Text:  where two or more particles become linked together in a way that their fates are intertwined, regardless of the distance separating them.

...
```

### Inspect raw JSON response

You can also use the `--raw` flag to view the complete JSON structure before parsing:

```sh
python3 vertex_stream.py --raw
```

This displays the full JSON array returned by Vertex AI, then continues with normal text output. Combine flags to see both raw structure and chunk metadata:

```sh
python3 vertex_stream.py --raw --chunks
```