---
title: Route Google Gemini CLI traffic through {{site.ai_gateway}}
permalink: /how-to/use-gemini-cli-with-ai-gateway/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Google Gemini CLI traffic using AI Proxy

products:
  - gateway
  - ai-gateway

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
  q: How do I run Google Gemini CLI through {{site.ai_gateway}}?
  a: Configure the AI Proxy plugin to forward requests to Google Gemini, then enable the File Log plugin to inspect traffic, and point Gemini CLI to the local proxy endpoint so all LLM requests go through the Gateway for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: Google Gemini API
      include_content: prereqs/gemini
      icon_url: /assets/icons/gcp.svg
    - title: Gemini CLI
      icon_url: /assets/icons/gcp.svg
      content: |
        This tutorial uses the Google Gemini CLI. Install Node.js 18+ if needed (verify with `node --version`), then install and launch the Gemini CLI.

        1. Run the following command in your terminal to install the Gemini CLI:

            ```sh
            npm install -g @google/gemini-cli
            ```

        2. Once the installation process is complete, verify the installation:

            ```sh
            gemini --version
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

First, let's configure the [AI Proxy](/plugins/ai-proxy/) plugin. The Gemini CLI expects to communicate with Google's Gemini API using the chat endpoint. The plugin handles authentication using a query parameter and forwards requests to the specified model. CLI tools installed across multiple developer machines typically require distributing API keys to each installation, which exposes credentials and makes rotation difficult.

Routing CLI tools through {{site.ai_gateway}} removes this requirement. Developers authenticate against the gateway instead of directly to AI providers. You can centralize authentication, enforce [rate limits](/plugins/ai-rate-limiting-advanced/), [track usage costs](/plugins/ai-rate-limiting-advanced/#token-count-strategies), [enforce guardrails](/ai-gateway/#guardrails-and-content-safety), and [cache repeated requests](/plugins/ai-semantic-cache/).

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        max_request_body_size: 4194304
        logging:
          log_statistics: true
          log_payloads: true
        route_type: llm/v1/chat
        llm_format: gemini
        auth:
          param_name: key
          param_value: ${gemini_api_key}
          param_location: query
        model:
          provider: gemini
          name: gemini-2.5-flash
variables:
  gemini_api_key:
    value: $GEMINI_API_KEY
{% endentity_examples %}

## Configure the File Log plugin

Now, let's configure the [File Log](/plugins/file-log/) plugin to inspect the traffic between Gemini CLI and {{site.ai_gateway}} by attaching a File Log plugin to the Service. This creates a local log file for examining requests and responses as Gemini CLI runs through {{site.base_gateway}}.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      config:
        path: "/tmp/gemini.json"
{% endentity_examples %}

## Export environment variables

Open a new terminal window and export the variables that the Gemini CLI will use. Point `GOOGLE_GEMINI_BASE_URL` to the local proxy endpoint where LLM traffic from Gemini CLI will route:

{% on_prem %}
content: |
  ```sh
  export GOOGLE_GEMINI_BASE_URL="http://localhost:8000/anything"
  export GEMINI_API_KEY="YOUR-GEMINI-API-KEY"
  ```
{% endon_prem %}

{% konnect %}
content: |
  ```sh
  export GOOGLE_GEMINI_BASE_URL="http://localhost:8000/anything"
  export GEMINI_API_KEY="YOUR-GEMINI-API-KEY"
  ```

  If you're using a different {{site.konnect_short_name}} proxy URL, be sure to replace `http://localhost:8000` with your proxy URL.
{% endkonnect %}


## Validate the configuration

Now you can test the Gemini CLI setup.

1. In the terminal where you exported your Gemini environment variables, run:

   ```sh
   gemini --model gemini-2.5-flash
   ```

   You should see the Gemini CLI interface start up.

2. Run a command to test the connection:

   ```text
   Tell me about prisoner's dilemma.
   ```

   Expected output will show the model's response to your prompt.

3. In your other terminal window, check that LLM traffic went through {{site.ai_gateway}}:

    ```sh
   docker exec kong-quickstart-gateway cat /tmp/gemini.json | jq
    ```

   Look for entries similar to:

   ```json
   {
     ...
     "ai": {
       "proxy": {
         "usage": {
           "prompt_tokens": 7795,
           "completion_tokens": 483,
           "total_tokens": 8278,
           "time_per_token": 10.513457556936,
           "time_to_first_token": 845
         },
         "meta": {
           "provider_name": "gemini",
           "request_model": "gemini-2.5-flash",
           "response_model": "gemini-2.5-flash",
           "llm_latency": 5078,
           "request_mode": "stream"
         }
       }
     }
     ...
   }
   ```
{:.no-copy-code}