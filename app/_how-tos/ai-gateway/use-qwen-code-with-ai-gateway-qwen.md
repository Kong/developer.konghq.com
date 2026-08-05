---
title: "Route Qwen Code CLI traffic through {{site.ai_gateway}} and Dashscope"
permalink: /ai-gateway/use-qwen-code-with-ai-gateway-qwen/
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
  a: Create an AI Model Provider and AI Model, then point Qwen Code CLI to the local proxy endpoint so all requests go through {{site.ai_gateway}} for monitoring and control.

tools:
  - kongctl

prereqs:
  inline:
    - title: DashScope
      icon_url: /assets/icons/dashscope.svg
      content: |
        Get an API key from the [Alibaba Cloud DashScope console](https://dashscope.aliyuncs.com/) and export it as the **full `Authorization` header value** (including the `Bearer` prefix):

        ```sh
        export DASHSCOPE_AUTH_HEADER="Bearer YOUR_DASHSCOPE_KEY"
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

---

## Create an AI Model Provider entity

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
  - ref: generic-dashscope
    ai_gateway: ai-quickstart
    name: generic-dashscope
    display_name: "generic-dashscope"
    type: dashscope
    config:
      auth:
        type: basic
        headers:
        - name: Authorization
          value: !env DASHSCOPE_AUTH_HEADER
EOF
```

In this example, we're setting up the AI Model Provider with:

* `type: dashscope`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-dashscope`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. `header_value: !env DASHSCOPE_AUTH_HEADER` loads the value from your environment at apply time instead of embedding it in the YAML, and `kongctl` redacts it in plan and diff output. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model entity

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
  - ref: my-qwen-dashscope
    ai_gateway: ai-quickstart
    name: my-qwen-dashscope
    display_name: "my-qwen-dashscope"
    type: model
    formats:
      - type: openai
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - my-qwen-dashscope
    targets:
      - name: qwen-plus
        provider: generic-dashscope
        config:
          type: dashscope
    policies: []
    capabilities:
      - generate
EOF
```

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-qwen-dashscope`: A unique identifier for this model.
* `formats: [type: openai]`: Declares that this model accepts requests in an OpenAI-compatible format.
* `config.route.paths: [/]`: Configures the custom base path where this model's Routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability.
* `targets`: Specifies which upstream AI Model Provider model to route requests to. Here, `generic-dashscope` references the AI Provider we created earlier, and `name: qwen-plus` specifies which OpenAI model to call upstream.

## Validate the configuration

Now you can start a Qwen Code CLI session that points it to the local {{site.ai_gateway}} endpoint:

```sh
OPENAI_BASE_URL="http://localhost:8000/" OPENAI_API_KEY=$DASHSCOPE_AUTH_HEADER qwen --model my-qwen-dashscope
```

You should see the Qwen Code CLI interface start up. Ask a simple question to confirm that requests reach {{site.ai_gateway}}.

```text
Explain the singleton pattern in Python.
```
