---
title: "Route Qwen Code CLI traffic through {{site.ai_gateway}}"
permalink: /ai-gateway/use-qwen-code-with-ai-gateway/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Qwen Code CLI traffic.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'


tags:
  - ai

tldr:
  q: How do I run Qwen Code CLI through {{site.ai_gateway}}?
  a: Create an AI Model PRovider and AI Model, then point Qwen Code CLI to the local proxy endpoint so all requests go through {{site.ai_gateway}} for monitoring and control.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
    - title: Qwen Code CLI
      icon_url: /assets/icons/qwen.svg
      content: |
        This tutorial uses the Qwen Code CLI tool. Install Node.js 18+ if needed (verify with `node --version`), then install and launch Qwen Code CLI:

        1. Run the following command in your terminal to install the Qwen Code CLI:
            ```sh
            npm install -g @qwen-code/qwen-code
            ```

        2. Once the installation process is complete, verify the installation:
            ```sh
            qwen --version
            ```

        3. The CLI will display the installed version number.

---

## Create an AI Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection to OpenAI and store your authentication credentials:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: ai-quickstart
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
        - name: Authorization
          value: !env OPENAI_AUTH_HEADER
EOF
```

In this example, we're setting up the AI Model Provider with:

* `type: openai`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-openai`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. `header_value: !env OPENAI_AUTH_HEADER` loads the value from your environment at apply time instead of embedding it in the YAML, and `kongctl` redacts it in plan and diff output. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_models:
  - ref: my-qwen-openai
    ai_gateway: ai-quickstart
    name: my-qwen-openai
    display_name: "my-qwen-openai"
    type: model
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
      model:
        alias: my-qwen-openai
    targets:
      - name: gpt-5-mini
        provider: generic-openai
        config:
          type: openai
    policies: []
    capabilities:
      - generate
EOF
```

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-qwen-openai`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively, even though the upstream model is OpenAI.
* `config.route.paths: [/]`: Configures the custom base path where this model's Routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability. For a model using the `anthropic` format, the `generate` capability creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: generic-openai` references the AI Provider we created earlier, and `name: gpt-5-mini` specifies which OpenAI model to call upstream.

## Export environment variables

Open a new terminal window and export the variables that Qwen Code CLI will use. Point `OPENAI_BASE_URL` to the local proxy endpoint where LLM traffic from Qwen Code CLI will route:

{% on_prem %}
content: |
  ```sh
  export OPENAI_BASE_URL="http://localhost:8000/anything"
  export OPENAI_API_KEY="YOUR OPENAI API KEY"
  export OPENAI_MODEL="gpt-5"
  ```
{% endon_prem %}

{% konnect %}
content: |
  ```sh
  export OPENAI_BASE_URL="http://localhost:8000/anything"
  export OPENAI_API_KEY="YOUR OPENAI API KEY"
  export OPENAI_MODEL="gpt-5"
  ```

  If you're using a different {{site.konnect_short_name}} proxy URL, be sure to replace `http://localhost:8000` with your proxy URL.
{% endkonnect %}

{:.info}
> Make sure that `OPENAI_MODEL` variable points to the same model configured for the AI Proxy plugin.


## Validate the configuration

Now you can test the Qwen Code CLI setup.

1. In the terminal where you exported your environment variables, run:

   ```sh
   qwen
   ```

   You should see the Qwen Code CLI interface start up.

2. Run a command to test the connection:

   ```text
   Explain the singleton pattern in Python.
   ```

   Expected output will show the model's response to your prompt.

3. Check that LLM traffic went through {{site.ai_gateway}}:

   ```sh
   docker exec kong-quickstart-gateway cat /tmp/qwen.json | jq
   ```

   Look for entries similar to:

   ```json
   {
     ...
     "request": {
       "size": 53534,
       "uri": "/qwen/chat/completions",
       "method": "POST",
       "headers": {
         "user-agent": "QwenCode/0.6.2 (darwin; arm64)",
         "content-type": "application/json"
       }
     },
     "response": {
       "status": 200,
       "size": 36922,
       "headers": {
         "x-kong-llm-model": "openai/gpt-5",
         "content-type": "text/event-stream; charset=utf-8"
       }
     },
     "latencies": {
       "proxy": 8289,
       "kong": 43,
       "request": 9889
     }
     ...
   }
   ```
{:.no-copy-code}