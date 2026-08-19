---
title: Route Google Gemini CLI traffic through {{site.ai_gateway}}
permalink: /ai-gateway/use-gemini-cli-with-ai-gateway/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Google Gemini CLI traffic to a Gemini model

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.0'

entities:
  - ai-model-provider
  - ai-model

tags:
  - ai
  - gemini

tldr:
  q: How do I run Google Gemini CLI through {{site.ai_gateway}}?
  a: Create an AI Model Provider entity to store your Gemini API key and an AI Model entity that routes to it, then point Gemini CLI's `GOOGLE_GEMINI_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests pass through the gateway for monitoring and control.

prereqs:
  inline:
    - title: Gemini API key
      content: |
        1. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey).
        1. Export the API key as a variable:
           ```bash
           export GEMINI_API_KEY='YOUR_GEMINI_API_KEY'
           ```
    - title: Gemini CLI
      icon_url: /assets/icons/ai-tools/gemini-cli.svg
      content: |
        This tutorial uses the Google Gemini CLI. Install Node.js 18+ if needed (verify with `node --version`), then install the Gemini CLI:

        ```sh
        npm install -g @google/gemini-cli
        ```

        Verify the installation:

        ```sh
        gemini --version
        ```

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---

## Create an AI Model Provider and AI Model

Gemini CLI expects to talk to {{ site.google }}'s {{ site.gemini }} API directly, authenticating with an API key. Distributing that key to every developer machine running the CLI exposes credentials and makes rotation difficult. Routing Gemini CLI through {{site.ai_gateway}} instead removes this requirement: developers authenticate against the gateway, and {{site.ai_gateway}} injects the real credential upstream.

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) that stores your Gemini API key as the `x-goog-api-key` header, so {{site.ai_gateway}} injects it into every upstream request and Gemini CLI never handles the real key. Then create an [AI Model](/ai-gateway/entities/ai-model/) using Gemini's native format, exposed at `/gemini` and routed to `gemini-3.5-flash` through that provider: the `generate` capability serves Gemini's `generateContent` and `streamGenerateContent` endpoints, and `config.route.model` lets Gemini CLI request the model by the alias `my-gemini-model` instead of the real upstream name. Create both entities in a single `kongctl` apply command so the model can reference the provider:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-gemini-account
    ai_gateway: !lookup name:ai-quickstart
    name: my-gemini-account
    display_name: "my-gemini-account"
    type: gemini
    config:
      auth:
        type: basic
        headers:
          - name: x-goog-api-key
            value: !env GEMINI_API_KEY
ai_gateway_models:
  - ref: my-gemini-model
    ai_gateway: !lookup name:ai-quickstart
    name: my-gemini-model
    display_name: "my-gemini-model"
    type: model
    enabled: true
    formats: [{ type: gemini }]
    config:
      route:
        paths: [/gemini]
        model:
          path_param: model_name
          values: [my-gemini-model]
      max_request_body_size: 4194304
    capabilities: [generate]
    targets:
      - name: gemini-3.5-flash
        provider: !ref my-gemini-account#name
        config:
          type: gemini
{% endentity_examples %}

## Run Gemini CLI

{:.warning}
> Make sure you authenticate using a [Gemini API key](https://geminicli.com/docs/get-started/authentication/#gemini-api)

Point `GOOGLE_GEMINI_BASE_URL` at the local proxy endpoint where LLM traffic from Gemini CLI routes and start a Gemini CLI session:

<!-- vale off -->
{% validation gemini %}
model: my-gemini-model
base_url: http://localhost:8000/gemini
prompt: Tell me about the prisoner's dilemma.
{% endvalidation %}
<!-- vale on -->

Expected output shows the model's response to your prompt, proxied through {{site.ai_gateway}} to the Gemini model configured in the AI Model entity's `targets`.
