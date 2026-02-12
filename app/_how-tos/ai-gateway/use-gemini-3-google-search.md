---
title: Use Gemini's googleSearch tool with AI Proxy Advanced in {{site.ai_gateway}}
permalink: /how-to/use-gemini-3-google-search/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Gemini Built-in Tools
    url: https://ai.google.dev/gemini-api/docs/function-calling

description: "Configure the AI Proxy Advanced plugin to use Gemini's built-in `googleSearch` tool for real-time web searches."

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

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
  q: How do I use Gemini's googleSearch tool with the AI Proxy Advanced plugin?
  a: Configure the AI Proxy Advanced plugin with the Gemini provider and gemini-3-pro-preview model, then declare the googleSearch tool in your requests using the OpenAI tools array.

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
    - title: OpenAI SDK
      include_content: prereqs/openai-sdk
      icon_url: /assets/icons/openai.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: What version of {{site.base_gateway}} supports googleSearch?
    a: |
      The `googleSearch` tool requires {{site.base_gateway}} 3.13 or later.
  - q: How does googleSearch differ from OpenAI function calling?
    a: |
      Gemini's `googleSearch` is a built-in capability that Gemini uses automatically when needed. It does not create explicit `tool_calls` objects in the response. Search results are integrated directly into the response content.
  - q: Can I force Gemini to use search for every query?
    a: |
      No. Gemini decides when to use search based on the query. Including the `googleSearch` tool declaration gives Gemini the capability, but it only uses search when the query requires current information.
  - q: Does googleSearch work with structured output?
    a: |
      Yes. You can combine `tools: [{"googleSearch": {}}]` with `response_format: {"type": "json_object"}` to get search results formatted as JSON.
---

## Configure the plugin

First, configure AI Proxy Advanced to use the gemini-3-pro-preview model via Vertex AI:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
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
                gemini:
                  api_endpoint: aiplatform.googleapis.com
                  project_id: ${gcp_project_id}
                  location_id: global
            auth:
              allow_override: false
              gcp_use_service_account: true
              gcp_service_account_json: ${gcp_service_account_json}
variables:
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
{% endentity_examples %}

## Use the OpenAI SDK with `googleSearch`

Gemini 3 models support built-in tools including `googleSearch`, which allows the LLM to retrieve current information from the web. Unlike OpenAI function calling, Gemini's built-in tools work automatically. The model decides when to use search based on the query, and integrates results directly into the response. For more information, see [Gemini Built-in Tools](https://ai.google.dev/gemini-api/docs/function-calling).

To enable the `googleSearch` tool, add it to the `tools` array in your request. The tool declaration tells Gemini it has access to web search. Gemini uses this capability when the query requires current information.

Create a Python script to test the `googleSearch` tool:

```py
cat << 'EOF' > google-search.py
#!/usr/bin/env python3
"""Test Gemini 3 googleSearch tool via {{site.ai_gateway}}"""
from openai import OpenAI
import json
client = OpenAI(
    base_url="http://localhost:8000/anything",
    api_key="ignored"
)
print("Testing Gemini 3 googleSearch tool")
print("=" * 50)
print("\n=== Step 1: Current weather data ===")
response = client.chat.completions.create(
    model="gemini-3-pro-preview",
    messages=[
        {"role": "user", "content": "What's the current weather in San Francisco?"}
    ],
    tools=[
        {"googleSearch": {}}
    ]
)
content = response.choices[0].message.content
print(f"Response includes current data: {'✓' if '2025' in content else '✗'}")
print(f"\n{content}\n")
print("\n=== Step 2: Search with JSON output ===")
response = client.chat.completions.create(
    model="gemini-3-pro-preview",
    messages=[
        {"role": "user", "content": "Find the top 3 AI conferences in 2025. Return as JSON with name, date, location fields."}
    ],
    tools=[
        {"googleSearch": {}}
    ],
    response_format={"type": "json_object"}
)
content = response.choices[0].message.content
if content.startswith("```"):
    lines = content.split("\n")
    content_clean = "\n".join(lines[1:-1])
else:
    content_clean = content
try:
    parsed = json.loads(content_clean)
    print(f"✓ Valid JSON response")
    print(f"  Type: {type(parsed).__name__}")
    if isinstance(parsed, list):
        print(f"  Items: {len(parsed)}")
except Exception as e:
    print(f"Parse result: {e}")
print(f"\n{content}\n")
print("\n=== Step 3: Query without search need ===")
response = client.chat.completions.create(
    model="gemini-3-pro-preview",
    messages=[
        {"role": "user", "content": "What is 2+2?"}
    ],
    tools=[
        {"googleSearch": {}}
    ]
)
content = response.choices[0].message.content
print(f"Simple answer: {content}\n")
print("=" * 50)
print("Complete")
EOF
```

This script goes through three scenarios:

1. **Current data query**: Asks for real-time weather information. Gemini uses search to retrieve current data.
2. **Structured output with search**: Requests conference information formatted as JSON. Combines search with structured output.
3. **Query without search need**: Asks a simple math question. Gemini answers directly without using search.

The OpenAI SDK sends requests to {{site.ai_gateway}} using the OpenAI chat completions format. The `tools` array declares available capabilities. {{site.ai_gateway}} transforms the OpenAI-format request into Gemini's native format, forwards it to Vertex AI, and converts the response back to OpenAI format. Search results appear directly in the response content, not as separate `tool_calls` objects.

Run the script:

```sh
python3 google-search.py
```

Example output:

````text
Testing Gemini 3 googleSearch tool
==================================================

=== Test 1: Current Weather Data ===
Response includes current data: ✓

As of 1:30 AM PST on Thursday, December 11, 2025, the weather in San Francisco is clear with a temperature of 46°F (8°C).

Here are the details:
*   Feels Like: 43°F (6°C)
*   Humidity: 91%
*   Wind: NNE at 7-8 mph
*   Forecast: Expect sunny skies later today with a high near 56°F to 58°F.


=== Test 2: Search with JSON Output ===
✓ Valid JSON response
  Type: list
  Items: 3
```json
[
  {
    "name": "CVPR 2025",
    "date": "June 11–15, 2025",
    "location": "Nashville, Tennessee, USA"
  },
  {
    "name": "ICML 2025",
    "date": "July 13–19, 2025",
    "location": "Vancouver, Canada"
  },
  {
    "name": "NeurIPS 2025",
    "date": "December 2–7, 2025",
    "location": "San Diego, California, USA"
  }
]
```


=== Test 3: Query Without Search Need ===
Simple answer: 2 + 2 is 4.

==================================================
Complete
````

The first test shows current weather data with a specific timestamp, confirming that Gemini used search. The second test returns structured JSON with conference information. The third test demonstrates that Gemini answers simple questions directly without using search, even when the tool is available.