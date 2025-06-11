---
title: Control prompt size with the AI Compressor plugin
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /plugins/ai-rag-injector/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Learn how to use the AI Compressor plugin alongside the RAG Injector and AI Prompt Decorator plugins to keep prompts lean, reduce latency, and avoid token limit errors

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.11'

plugins:
  - ai-proxy-advanced
  - ai-rag-injector
  - ai-prompt-decorator

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I keep RAG prompts under control and avoid bloated LLM requests?
  a: |
    Use the AI RAG Injector in combination with the AI Prompt Compressor plugin to retrieve relevant chunks and keep the final prompt within reasonable limits to prevent:
    - Increased latency
    - Token limit errors
    - Unexpected bills from your LLM provider

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Redis stack
      content: |
          To complete this tutorial, you must have a [Redis stack](https://redis.io/docs/latest/) configured in your environment.
          Set your Redis host as an environment variable:
          ```sh
          export DECK_REDIS_HOST='YOUR-REDIS-HOST'
          ```
      icon_url: /assets/icons/redis.svg
    - title: Kong Prompt Compressor service via Cloudsmith
      content: |
        To complete this tutorial, you must run the Kong Compressor Service. Kong provides Compressor service as a private Docker image in a Cloudsmith repository. Contact [Kong Support](https://support.konghq.com/support/s/) to get access to it. Once you've received your Cloudsmith access token, run the following commands in Docker to pull the image:
        ```sh
        docker login docker.cloudsmith.io
        ```

        Docker will then prompt you to enter username and password:

        ```bash
        Username: kong/ai-compress
        Password: <your_token>
        ```
        To pull an image:

        ```bash
        docker pull docker.cloudsmith.io/kong/ai-compress/<image-name>:<tag>
        ```

        Replace `<image-name>` and `<tag>` with the appropriate image and version, such as:

        ```bash
        docker pull docker.cloudsmith.io/kong/ai-compress/service:v0.0.2
        ```
        Once you've pulled the image, build and run it in your Docker container.
      icon_url: /assets/icons/cloudsmith.svg
    - title: Python 3
      content: |
        To complete this tutorial, you'll need **Python (version 3.7 or later)** and `pip` installed on your machine. You can verify it by running:

        ```bash
        python3
        python3 -m pip --version
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
---

## Configure the AI Proxy Advanced plugin

First, you'll need to configure the AI Proxy Advanced plugin to proxy prompt requests to your model provider, and handle authentication:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI RAG Injector plugin

Next, configure the AI RAG Injector plugin to insert the RAG context into the user message only, and wrap it with <LLMLINGUA> tags so the AI Prompt Compressor plugin can compress it effectively.

{% entity_examples %}
entities:
  plugins:
  - name: ai-rag-injector
    config:
      fetch_chunks_count: 5
      inject_as_role: user
      inject_template: <LLMLINGUA><CONTEXT></LLMLINGUA> | <PROMPT>
      embeddings:
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: text-embedding-3-large
      vectordb:
        strategy: redis
        redis:
          host: ${redis_host}
          port: 6379
        distance_metric: cosine
        dimensions: 3072
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}

{:.info}
> If your Redis instance runs in a separate Docker container from Kong, use `host.docker.internal` for `vectordb.redis.host`.
>
> If you're using a model other than `text-embedding-3-large`, be sure to update the `vectordb.dimensions` value to match the model’s embedding size.

## Ingest data to Redis

TBA

## Test ingestion

TBA

## Configure the AI Prompt Compressor plugin

Then, configure the AI Prompt Compressor plugin to apply compression to the wrapped RAG context using defined token ranges and compression settings.

{% entity_examples %}
entities:
  plugins:
    - name: ai-rag-injector
      config:
        compression_ranges:
          - max_tokens: 100
            min_tokens: 20
            value: 0.8
          - max_tokens: 1000000
            min_tokens: 100
            value: 0.3
        compressor_type: rate
        compressor_url: http://compress-service:8080
        keepalive_timeout: 60000
        log_text_data: false
        stop_on_error: true
        timeout: 10000
{% endentity_examples %}