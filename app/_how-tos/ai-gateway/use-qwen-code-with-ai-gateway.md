---
title: "Route Qwen Code CLI traffic through {{site.ai_gateway}}"
permalink: /how-to/use-qwen-code-with-ai-gateway/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Qwen Code CLI traffic using AI Proxy with OpenAI-compatible endpoints

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.10'

plugins:
  - ai-proxy
  - file-log

entities:
  - service
  - route
  - plugin

tags:
  - ai

tldr:
  q: How do I run Qwen Code CLI through {{site.ai_gateway}}?
  a: Configure AI Proxy to forward requests to OpenAI, enable the File Log plugin to inspect traffic, and point Qwen Code CLI to the local proxy endpoint so all requests go through the Gateway for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI API Key
      icon_url: /assets/icons/openai.svg
      content: |
        This tutorial requires an OpenAI API key with access to GPT models. You can obtain an API key from the [OpenAI Platform](https://platform.openai.com/api-keys).

        Export the OpenAI API key as an environment variable:
        ```sh
        export DECK_OPENAI_API_KEY='YOUR OPENAI API KEY'
        ```
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

automated_tests: false
---
## Configure the AI Proxy plugin

First, configure the [AI Proxy](/plugins/ai-proxy/) plugin. The [Qwen Code CLI](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/auth/) uses OpenAI-compatible endpoints for LLM communication. The plugin handles authentication using a bearer token header and forwards requests to the specified model.

CLI tools installed across multiple developer machines typically require distributing API keys to each installation, which exposes credentials and makes rotation difficult. Routing CLI tools through {{site.ai_gateway}} removes this requirement. Developers authenticate against the gateway instead of directly to AI providers. You can centralize authentication, enforce [rate limits](/plugins/ai-rate-limiting-advanced/), [track usage costs](/plugins/ai-rate-limiting-advanced/#token-count-strategies), [enforce guardrails](/ai-gateway/#guardrails-and-content-safety), and [cache repeated requests](/plugins/ai-semantic-cache/).

{:.info}
> The `max_request_body_size` parameter is set to 4194304 bytes (4MB) to accommodate large code files and extended context windows that Qwen Code CLI sends during code analysis tasks.


{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        max_request_body_size: 4194304
        route_type: llm/v1/chat
        logging:
          log_statistics: true
          log_payloads: true
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: gpt-5
          options:
            max_tokens: 512
            temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the File Log plugin

Let's configure the [File Log](/plugins/file-log/) plugin to inspect the traffic between Qwen Code CLI and {{site.ai_gateway}}. This plugin will create a local log file for examining requests and responses as Qwen Code CLI runs through Kong.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      service: example-service
      config:
        path: "/tmp/qwen.json"
{% endentity_examples %}

## Export environment variables

Open a new terminal window and export the variables that Qwen Code CLI will use. Point `OPENAI_BASE_URL` to the local proxy endpoint where LLM traffic from Qwen Code CLI will route:

```sh
export OPENAI_BASE_URL="http://localhost:8000/anything"
export OPENAI_API_KEY="YOUR OPENAI API KEY"
export OPENAI_MODEL="gpt-5"
```
{: data-deployment-topology="on-prem" }

```sh
export OPENAI_BASE_URL="http://localhost:8000/anything"
export OPENAI_API_KEY="YOUR OPENAI API KEY"
export OPENAI_MODEL="gpt-5"
```
{: data-deployment-topology="konnect" }
If you're using a different {{site.konnect_short_name}} proxy URL, be sure to replace `http://localhost:8000` with your proxy URL.
{: data-deployment-topology="konnect" }

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