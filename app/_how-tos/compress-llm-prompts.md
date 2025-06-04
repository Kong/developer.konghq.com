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
  q: How do I
  a: You do


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
        docker pull ai-compressor-service
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

Hello