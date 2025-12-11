---
title: Use Gemini's thinkingConfig with AI Proxy Advanced in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Gemini Thinking Mode
    url: https://ai.google.dev/gemini-api/docs/thinking

description: "Configure the AI Proxy Advanced plugin to use Gemini's `thinkingConfig` feature for detailed reasoning traces."

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

tldr:
  q: How do I use Gemini's thinkingConfig with the AI Proxy Advanced plugin?
  a: Configure the AI Proxy Advanced plugin with the Gemini provider and gemini-3-pro-preview model, then pass thinkingConfig parameters via extra_body in your requests.

tools:
  - deck

prereqs:
  inline:
    - title: Vertex AI
      content: |
        Before you begin, you must get the following credentials from Google Cloud:

        - **Service Account Key**: A JSON key file for a service account with Vertex AI permissions
        - **Project ID**: Your Google Cloud project identifier
        - **Location ID**: The region where your Vertex AI endpoint is deployed (for example, `us-central1`)
        - **API Endpoint**: The Vertex AI API endpoint URL (typically `https://{location}-aiplatform.googleapis.com`)

        Export these values as environment variables:
        ```sh
        export GCP_SERVICE_ACCOUNT_JSON="<your-service-account-json>"
        export GCP_PROJECT_ID="<your-project-id>"
        ```
      icon_url: /assets/icons/gcp.svg
    - title: Python and OpenAI SDK
      content: |
        Install Python 3 and the OpenAI SDK:
        ```sh
        pip install openai
        ```
      icon_url: /assets/icons/python.svg
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
  - q: What version of {{site.base_gateway}} supports thinkingConfig?
    a: |
      The `thinkingConfig` feature requires {{site.base_gateway}} 3.13 or later (or 3.12.0.2+ with backport).
  - q: How are reasoning traces formatted in the response?
    a: |
      Reasoning traces are returned as part of the text content with `<thought>` tags for easy parsing. You can extract these sections programmatically or display them to end users.
  - q: Why don't I see reasoning traces in my response?
    a: |
      Complex queries are more likely to produce visible reasoning traces. Simple questions may not trigger the thinking mode. Try using more complex problems or increase the `thinking_budget` parameter.
  - q: How does thinking_budget affect performance?
    a: |
      Higher `thinking_budget` values (up to 200) increase response time but provide more detailed reasoning. Lower values produce faster responses with less detailed traces.
---

## Configure the plugin

First, let's configure AI Proxy Advanced to use the gemini-3-pro-preview models via Vertex AI:

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

## Use the OpenAI SDK with `thinkingConfig`

Gemini 3 models support a `thinkingConfig` feature that returns detailed reasoning traces alongside the final response. This allows you to see how the model arrived at its answer. For more information, see [Gemini Thinking Mode](https://ai.google.dev/gemini-api/docs/thinking).

The `thinkingConfig` supports the following parameters:

* `include_thoughts` (boolean): Set to `true` to include reasoning traces in the response.
* `thinking_budget` (integer): Controls the depth and detail of reasoning. Higher values (up to 200) produce more detailed reasoning traces but may increase latency.

Create a Python script using the OpenAI SDK:


```sh
cat < thinking-config.py
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="ignored"
)

response = client.chat.completions.create(
    model="gemini-3-pro-preview",
    messages=[
        {
            "role": "user",
            "content": "Three logicians walk into a bar. The bartender asks 'Do all of you want a drink?' The first logician says 'I don't know.' The second logician says 'I don't know.' The third logician says 'Yes!' Explain why each logician answered the way they did."
        }
    ],
    extra_body={
        "generationConfig": {
            "thinkingConfig": {
                "include_thoughts": True,
                "thinking_budget": 200
            }
        }
    }
)

content = response.choices[0].message.content

if '' in content:
    print("✓ Thoughts included in response\n")
else:
    print("✗ No thoughts found\n")

print(content)
EOF
```

This script sends a logic puzzle that requires multi-step reasoning. Complex queries like this are more likely to produce visible reasoning traces showing how the model analyzes the problem, deduces information from each response, and reaches its conclusion. The `thinking_budget` of 200 allows for detailed reasoning traces.

The OpenAI SDK sends requests to {{site.base_gateway}} using the OpenAI chat completions format. The `extra_body` parameter passes Gemini-specific configuration through to the model. {{site.base_gateway}} transforms the OpenAI-format request into Gemini's native format, forwards it to Vertex AI, and converts the response back to OpenAI format with reasoning traces wrapped in `<thought>` tags.


Now, let's run the script:

```sh
python3 thinking-config.py
```

Example output:

```text
✓ Thoughts included in response

<thought>**Calculating the Average Speed**

I've zeroed in on the core goal: figuring out the train's average speed. To get there, I'm breaking the trip into two segments. I've noted down the distance and time for the first part and need to find the distance for the second leg of the trip.

</thought>
To find the average speed for the entire journey, we need to use the formula for average speed:

$$\text{Average Speed} = \frac{\text{Total Distance}}{\text{Total Time}}$$

Here is the step-by-step calculation:

**Step 1: Calculate the total distance traveled.**
*   Distance in the first part: 120 km
*   Distance in the second part: 200 km
*   Total Distance = $120 \text{ km} + 200 \text{ km} = 320 \text{ km}$

**Step 2: Calculate the total time taken.**
*   Time for the first part: 2 hours
*   Time for the second part: 2 hours
*   Total Time = $2 \text{ hours} + 2 \text{ hours} = 4 \text{ hours}$

**Step 3: Calculate the average speed.**
Divide the total distance by the total time:
*   Average Speed = $320 \text{ km} / 4 \text{ hours}$
*   Average Speed = $80 \text{ km/h}$

**Answer:**
The average speed for the entire journey was **80 km/h**.
```

The response includes the model's reasoning process in the `<thought>` section, followed by the final answer with step-by-step calculations which solve the puzzle.