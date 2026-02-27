---
title: Use Gemini's thinkingConfig with AI Proxy Advanced in {{site.ai_gateway}}
permalink: /how-to/use-gemini-3-thinking-config/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
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
  - gemini
  - ai-sdks

tldr:
  q: How do I use Gemini's thinkingConfig with the AI Proxy Advanced plugin?
  a: Configure the AI Proxy Advanced plugin with the Gemini provider and gemini-3-pro-preview model, then pass thinkingConfig parameters via extra_body in your requests.

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
  - q: What version of {{site.base_gateway}} supports thinkingConfig?
    a: |
      The `thinkingConfig` feature requires {{site.base_gateway}} 3.13 or later.
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


```py
cat << 'EOF' > thinking-config.py
from openai import OpenAI
client = OpenAI(
    base_url="http://localhost:8000/anything",
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
if '<thinking>' in content:
    print("✓ Thoughts included in response\n")
else:
    print("✗ No thoughts found\n")
print(content)
EOF
```

This script sends a logic puzzle that requires multi-step reasoning. Complex queries like this are more likely to produce visible reasoning traces showing how the model analyzes the problem, deduces information from each response, and reaches its conclusion. The [`thinking_budget`](https://ai.google.dev/gemini-api/docs/thinking#set-budget) of 200 allows for detailed reasoning traces.

The OpenAI SDK sends requests to {{site.ai_gateway}} using the OpenAI chat completions format. The `extra_body` parameter passes Gemini-specific configuration through to the model. {{site.ai_gateway}} transforms the OpenAI-format request into Gemini's native format, forwards it to Vertex AI, and converts the response back to OpenAI format with reasoning traces wrapped in `<thought>` tags.


Now, let's run the script:

```sh
python3 thinking-config.py
```

Example output:

```text
✓ Thoughts found

=== Content ===
<thought>**Dissecting the Riddle's Elements**

I'm focused on the riddle's core. The bartender's question sets the stage, and each logician's response is key. I'm noting how the information unfolds with each "I don't know," allowing the final "Yes!" to make logical sense. Each element in the question and answer is important.


</thought>
This is a classic logic puzzle disguised as a joke. To understand the answers, you have to look at the specific question asked: **"Do *all* of you want a drink?"**

Here is the breakdown of each logician’s thought process:

**The First Logician**
*   **The Situation:** The first logician wants a drink.
*   **The Logic:** If he *didn't* want a drink, the answer to "Do **all** of you want a drink?" would be "No" (because if one person doesn't want one, they don't *all* want one). However, simply knowing that *he* wants a drink isn't enough to answer "Yes," because he doesn't know what the other two want.
*   **The Answer:** Since he cannot say "No" (because he wants one) but cannot say "Yes" (because he doesn't know about the others), his only truthful logical answer is **"I don't know."**

**The Second Logician**
*   **The Situation:** The second logician also wants a drink.
*   **The Logic:** She hears the first logician say "I don't know." She deduces that the first logician *must* want a drink (otherwise he would have said "No"). Now she looks at her own desire. If *she* didn't want a drink, she would answer "No" (because the condition "all" would fail). But she *does* want a drink. However, like the first logician, she doesn't know what the third logician wants.
*   **The Answer:** Since she wants a drink but is unsure of the third person, she also must answer **"I don't know."**

**The Third Logician**
*   **The Situation:** The third logician wants a drink.
*   **The Logic:** He has heard the first two answer "I don't know."
    *   From the first answer, he deduces Logician #1 wants a drink.
    *   From the second answer, he deduces Logician #2 wants a drink.
*   **The Answer:** Since he knows he wants a drink himself, and he has deduced that the other two also want drinks, he now has complete information. Everyone wants a drink. Therefore, he can definitively answer **"Yes!"**
```

The response includes the model's reasoning process in the `<thought>` section, followed by the final answer with step-by-step calculations which solve the puzzle.