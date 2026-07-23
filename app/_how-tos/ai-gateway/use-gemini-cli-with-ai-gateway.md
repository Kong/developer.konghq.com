---
title: Route Google Gemini CLI traffic through {{site.ai_gateway}}
permalink: /ai-gateway/use-gemini-cli-with-ai-gateway/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/v1/

description: Configure {{site.ai_gateway}} to proxy Google Gemini CLI traffic using AI Proxy

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

tags:
  - ai

tldr:
  q: How do I run Google Gemini CLI through {{site.ai_gateway}}?
  a: Configure an AI Model Provider and AI Model, then point Gemini CLI to the local proxy endpoint so all LLM requests go through the Gateway for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: Gemini API key
      content: |
        1. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey).
        1. Export the API key as a variable:
           ```bash
           export GEMINI_API_KEY='bearer YOUR_GEMINI_API_KEY'
           ```
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

---

## Create an AI Model Provider

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection to Gemini and store your API key:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: my-gemini-account
    ai_gateway: ai-quickstart
    name: my-gemini-account
    display_name: "my-gemini-account"
    type: gemini
    config:
      auth:
        type: basic
        headers:
        - name: x-goog-api-key
          value: !env GEMINI_API_KEY
EOF
```

In this example, we're setting up the AI Model Provider with:

* `type: gemini`: Specifies that this provider connects to the Gemini service using Gemini's standard API format.
* `name: my-gemini-account`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your Gemini API key. `value: !env GEMINI_API_KEY` loads the value from your environment at apply time instead of embedding it in the YAML, and `kongctl` redacts it in plan and diff output. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use:

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
  - ref: my-gemini-model
    ai_gateway: ai-quickstart
    name: my-gemini-model
    display_name: "my-gemini-model"
    type: model
    formats:
      - type: gemini
    config:
      route:
        paths:
          - /
      model:
        alias: my-gemini-model
    targets:
      - name: gemini-2.5-flash
        provider: my-gemini-account
        config:
          type: gemini
    policies: []
    capabilities:
      - generate
EOF
```

## Export environment variables

Open a new terminal window and export the variables that the {{ site.gemini }} CLI will use. Point `GOOGLE_GEMINI_BASE_URL` to the local proxy endpoint where LLM traffic from {{ site.gemini }} CLI will route:


```sh
export GOOGLE_GEMINI_BASE_URL="http://localhost:8000/"
export GEMINI_API_KEY="YOUR-GEMINI-API-KEY"
```

If you're using a different {{site.konnect_short_name}} proxy URL, be sure to replace `http://localhost:8000` with your proxy URL.


## Validate the configuration

Now you can test the {{ site.gemini }} CLI setup.

1. In the terminal where you exported your {{ site.gemini }} environment variables, run:

   ```sh
   gemini --model gemini-2.5-flash
   ```

   You should see the {{ site.gemini }} CLI interface start up.

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