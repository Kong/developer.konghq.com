---
title: Set up AI Proxy Advanced with OpenAI in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using OpenAI.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I use the
  a: Create a Gateway Service and a Route, then

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Codex CLI
      icon_url: /assets/icons/openai.svg
      content: |
        This tutorial uses the OpenAI Codex CLI. Install Node.js 18+ if needed (verify with `node --version`), then install and launch Codex:

        1. Run the following command in your terminal to install the Codex CLI:

            ```sh
            npm install -g @openai/codex
            ```

        2. Once the installation process is complete, run the following command:

            ```sh
            codex
            ```
        3. The CLI will prompt you to authenticate in your browser using your OpenAI account.

        4. Once authenticated, close the Codex CLI session by hitting <kbd>ctrl</kbd> + <kbd>c</kbd> on macOS or <kbd>ctrl</kbd> + <kbd>break</kbd> on Windows.
  entities:
    services:
      - codex-service
    routes:
      - codex-route

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

Let's configure the AI Proxy Advanced plugin. In this setup, we use the Responses route because the Codex CLI calls it by default. We don't hard-code a model in the plugin — Codex sends the model in each request. We also raise the body size limit to 128 KB to support larger prompts.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      service: codex-service
      config:
        genai_category: text/generation
        llm_format: openai
        max_request_body_size: 131072
        model_name_header: true
        response_streaming: allow
        balancer:
          algorithm: "round-robin"
          tokens_count_strategy: "total-tokens"
          latency_strategy: "tpot"
          retries: 3
          targets:
            - route_type: llm/v1/responses
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        logging:
          log_payloads: true
          log_statistics: true
        model:
          provider: "openai"

variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}


## Configure the request transformer plugin

To ensure that Codex forwards clean, predictable requests to OpenAI, we add a request transformer. This plugin normalizes the upstream URI and removes any extra path segments, so only the expected route reaches the OpenAI endpoint. This small guardrail avoids malformed paths and keeps the proxy behavior consistent.

{% entity_examples %}
entities:
  plugins:
    - name: request-transformer
      service: codex-service
      config:
        replace:
          uri: "/"
{% endentity_examples %}


Now, we can pre-validate our current configuration:


{% validation request-check %}
url: /codex
status_code: 200
method: POST
headers:
    - 'Content-Type: application/json'
body:
    model: gpt-4o
    input:
        - role: "user"
          content: "Ping"
{% endvalidation %}

## Export environment variables

Now, open a new terminal window and export the variables that the Codex CLI will use. We set a dummy API key here just to confirm the variable exists, and point `OPENAI_BASE_URL` to the local proxy endpoint where we route LLM traffic:

```sh
export OPENAI_API_KEY=sk-xxx
export OPENAI_BASE_URL=http://localhost:8000/codex
```

## Configure the File Log plugin

To see the exact payloads traveling between Codex and the AI Gateway, let's attach a File Log plugin to the service. This gives us a local log file so we can inspect requests and responses as Codex runs through Kong.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      service: codex-service
      config:
        path: "/tmp/file.json"
{% endentity_examples %}


## Start and use Codex CLI

1. In the terminal where you exported your environment variables, run:

   ```sh
   codex
   ```

   You should see:

   ```text
   │ >_ OpenAI Codex (v0.55.0)                 │
   │                                           │
   │ model:     gpt-5-codex   /model to change │
   │ directory: ~                              │
   ╰───────────────────────────────────────────╯

     To get started, describe a task or try one of these commands:

     /init - create an AGENTS.md file with instructions for Codex
     /status - show current session configuration
     /approvals - choose what Codex can do without approval
     /model - choose what model and reasoning effort to use
     /review - review any changes and find issues
   ```

2. Run a simple command to call Codex using the gpt-4o model:

   ```sh
   codex exec --model gpt-4o "Hello"
   ```

   Codex will prompt:

   ```text
     Would you like to run the following command?

     Reason: Need temporary network access so codex exec can reach the OpenAI API

     $ codex exec --model gpt-4o "Hello"

   › 1. Yes, proceed
     2. Yes, and don't ask again for this command
     3. No, and tell Codex what to do differently
   ```

   Select **Yes, proceed** and press <kbd>Enter</kbd>.

   Expected output:

   ```text
   • Ran codex exec --model gpt-4o "Hello"
     └ OpenAI Codex v0.55.0 (research preview)
       --------
       … +12 lines
       6.468
       Hi there! How can I assist you today?

   ─ Worked for 9s ────────────────────────────────────────────────────────────────

   • codex exec --model gpt-4o "Hello" returned: “Hi there! How can I assist you today?”
   ```

3. Check that LLM traffic went through Kong AI Gateway:

   ```sh
   docker exec kong-quickstart-gateway cat /tmp/file.json | jq
   ```

   Look for entries similar to:

   ```json
   {
     ...
     "ai": {
       "proxy": {
         "tried_targets": [
           {
             "ip": "0000.000.000.000",
             "route_type": "llm/v1/responses",
             "port": 443,
             "upstream_scheme": "https",
             "host": "api.openai.com",
             "upstream_uri": "/v1/responses",
             "provider": "openai"
           }
         ]
       }
     }
     ...
   }
   ```
