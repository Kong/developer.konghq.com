---
title: Route Google Gemini CLI traffic through Kong AI Gateway
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure AI Gateway to proxy Google Gemini CLI traffic using AI Proxy

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
  - request-transformer
  - file-log

entities:
  - service
  - route
  - plugin

tags:
  - ai

tldr:
  q: How do I run Google Gemini CLI through Kong AI Gateway?
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
        This tutorial uses the Google Gemini CLI. Install Node.js 18+ if needed (verify with `node --version`), then install and launch the Gemini CLI:

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
## Configure the AI Proxy plugin

First, let's configure the [AI Proxy](/plugins/ai-proxy/) plugin. The Gemini CLI expects to communicate with Google's Gemini API using the chat endpoint. The plugin handles authentication using a query parameter and forwards requests to the specified model.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      service: gemini-service
      config:
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

Now, let's configure the [File Log](/plugins/file-log/)  plugin to inspect the traffic between Gemini CLI and AI Gateway, attach a File Log plugin to the service. This creates a local log file for examining requests and responses as Gemini CLI runs through Kong.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      service: gemini-service
      config:
        path: "/tmp/gemini.json"
{% endentity_examples %}

## Export environment variables

Open a new terminal window and export the variables that the Gemini CLI will use. Point `GOOGLE_GEMINI_BASE_URL` to the local proxy endpoint where LLM traffic from Gemini CLI will route:

```sh
export GOOGLE_GEMINI_BASE_URL="http://localhost:8000/gemini"
export GEMINI_API_KEY="YOUR-GEMINI-API-KEY"
```
{: data-deployment-topology="on-prem" }

```sh
export GOOGLE_GEMINI_BASE_URL="export KONNECT_PROXY_URL="http://localhost:8000/gemini"
export GEMINI_API_KEY="YOUR-GEMINI-API-KEY"
```
If you're using a different {{site.konnect_short_name}} proxy URL, be sure to replace `http://localhost:8000` with your proxy URL.
{: data-deployment-topology="konnect" }


## Validate the configuration

Test the Gemini CLI setup:

1. In the terminal where you exported your Gemini environment variables, run:

   ```sh
   gemini --model gemini-2.5-flash
   ```

   You should see the Gemini CLI interface start up.

2. Run a test command to test the connection:

   ```text
   Tell me about prisoner's dilemma.
   ```

   Expected output will show the model's response to your prompt.

3. In your other terminal window, check that LLM traffic went through Kong AI Gateway:

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