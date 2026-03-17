---
title: Stream responses from Vertex AI through {{site.ai_gateway}} using Google Generative AI SDK
permalink: /how-to/use-vertex-sdk-for-streaming/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
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
  - ai-sdks

tldr:
  q: How do I stream responses from Vertex AI through {{site.ai_gateway}}?
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
    - title: Google Generative AI SDK
      content: |
        Install the Google Generative AI SDK:
         ```sh
        python3 -m pip install google-genai
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
    literal_block: true
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
from google import genai
from google.genai.types import HttpOptions
import os
import sys

PROJECT_ID = os.getenv("DECK_GCP_PROJECT_ID")
LOCATION = os.getenv("DECK_GCP_LOCATION_ID")

if not PROJECT_ID:
    print("Error: DECK_GCP_PROJECT_ID environment variable not set")
    sys.exit(1)

def vertex_stream(show_raw=False, show_chunks=False):
    """Stream responses from Vertex AI through Kong Gateway"""

    # Configure client to route through Kong Gateway
    client = genai.Client(
        vertexai=True,
        project=PROJECT_ID,
        location=LOCATION,
        http_options=HttpOptions(
            base_url="http://localhost:8000/gemini",
            api_version="v1"
        )
    )

    try:
        if show_raw:
            print("Streaming with raw output...\n")

        chunk_num = 0
        for chunk in client.models.generate_content_stream(
            model="gemini-2.0-flash-exp",
            contents="Explain quantum entanglement in one paragraph"
        ):
            chunk_num += 1

            if show_chunks:
                print(f"\n--- Chunk {chunk_num} ---")
                if hasattr(chunk, 'candidates') and chunk.candidates:
                    candidate = chunk.candidates[0]
                    if hasattr(candidate, 'finish_reason') and candidate.finish_reason:
                        print(f"Finish reason: {candidate.finish_reason}")
                    if hasattr(chunk, 'usage_metadata') and chunk.usage_metadata:
                        if hasattr(chunk.usage_metadata, 'total_token_count'):
                            print(f"Total tokens: {chunk.usage_metadata.total_token_count}")
                print("Text: ", end="")

            if show_raw:
                print(f"\nChunk {chunk_num}:", chunk)
                print("-" * 80)

            print(chunk.text, end="", flush=True)

            if show_chunks:
                print()

        if not show_chunks:
            print()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    show_raw = "--raw" in sys.argv
    show_chunks = "--chunks" in sys.argv
    vertex_stream(show_raw, show_chunks)
EOF
```


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
{:.no-copy-code}

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
Total tokens: None
Text: Quantum

--- Chunk 2 ---
Total tokens: None
Text:  entanglement is a

--- Chunk 3 ---
Total tokens: None
Text:  bizarre phenomenon where two or more particles become linked together in such a way that they

--- Chunk 4 ---
Total tokens: None
Text:  share the same fate, no matter how far apart they are. Measuring the properties

--- Chunk 5 ---
Total tokens: None
Text:  of one entangled particle instantaneously determines the corresponding properties of the other, even if they're separated by vast distances. This correlation isn't due to some pre-existing hidden

--- Chunk 6 ---
Finish reason: STOP
Total tokens: 100
Text:  information but is instead a fundamental connection arising from their shared quantum state, defying classical intuition about locality and causality.
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