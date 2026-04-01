---
title: "Secure GitHub MCP Server traffic with {{ site.base_gateway }} and {{site.ai_gateway}}"
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advance/
  - text: Key Auth plugin
    url: /plugins/key-auth/
permalink: /mcp/secure-mcp-traffic/
breadcrumbs:
  - /mcp/

description: Learn how to secure MCP traffic within GitHub remote MCP server with the Key Authentication plugin

series:
    id: mcp-traffic
    position: 1

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem

min_version:
  gateway: '3.11'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - mcp

tldr:
  q: How can I secure my MCP traffic using {{ site.base_gateway }}?
  a: |
    Enable the Key Authentication plugin on your MCP service and require API keys from Consumers. {{site.ai_gateway}} then enforces these keys on all incoming MCP requests, ensuring secure, authorized access.

    {:.info}
    > For further authentication of your MCP traffic you can also use [The OpenID Connect](/plugins/openid-connect/) (OIDC) plugin lets you integrate {{ site.base_gateway }} with an identity provider (IdP), or you can extend plugins to support fine-grained Authorization models via JWT claims or declarative [Access Control Lists](/plugins/acl/) (ACLs)


tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: GitHub
      content: |
        To complete this tutorial, you'll need access to GitHub, a GitHub repository, and a [Github Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

        Once you've created your Github Personal Access Token, export it as an environment variable by running the following command:

        ```bash
        export GITHUB_PAT='YOUR_GITHUB_TOKEN'
        ```
      icon_url: /assets/icons/third-party/github.svg
  entities:
    services:
        - example-clean-service
    routes:
        - example-clean-route


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

To enable model-driven access to remote tools, we’ll route MCP traffic through OpenAI using the AI Proxy Advanced plugin. In this tutorial, we’ll use the [OpenAI `/responses` API](https://cookbook.openai.com/examples/mcp/mcp_tool_guide) endpoint via the `llm/v1/responses` route type in the AI Proxy Advanced plugin to communicate with a GitHub-hosted remote MCP server. This approach simplifies integration: instead of routing each tool invocation through your backend, {{site.ai_gateway}} forwards model-generated requests directly to the MCP server. That server exposes standardized tools, giving you conversational control over your GitHub repositories—secured and governed by Kong’s built-in capabilities. No custom glue code is required to enable this integration.


{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/responses
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

## Enable the Key Authentication plugin on the Service

Enable Key Auth for the Service.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-clean-service
      config:
        key_names:
        - apikey
{% endentity_examples %}

## Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. The Consumer needs an API key to access any Services.

<!-- vale off -->
{% entity_examples %}
entities:
  consumers:
    - username: alex
      keyauth_credentials:
        - key: hello_world
{% endentity_examples %}
<!-- vale on -->

## Validate

After configuring the Key Authentication plugin, you can verify that it was configured correctly and is working, by sending requests with and without the API key you created for your Consumer.

The following request is valid, as it includes the `apikey` required by the Consumer:

<!-- vale off -->
{% validation request-check %}
  url: /anything
  method: POST
  headers:
    - 'Content-Type: application/json'
    - 'apikey: hello_world'
    - 'Authorization: Bearer $OPENAI_API_KEY'
  body:
    tools:
      - type: mcp
        server_label: gitmcp
        server_url: https://api.githubcopilot.com/mcp/
        require_approval: never
        headers:
            Authorization: Bearer $GITHUB_PAT
    input: How do I use GitHub MCP?
  status_code: 200
  message: 'OK'
{% endvalidation %}
<!-- vale on -->

On the following request, include an invalid value for `apikey`:

<!-- vale off -->
{% validation request-check %}
  url: /anything
  method: POST
  headers:
    - 'Content-Type: application/json'
    - 'apikey: another_key'
    - 'Authorization: Bearer $OPENAI_API_KEY'
  body:
    tools:
      - type: mcp
        server_label: gitmcp
        server_url: https://api.githubcopilot.com/mcp/
        require_approval: never
        headers:
          Authorization: Bearer $GITHUB_PAT
    input: How do I use GitHub MCP?
  status_code: 401
  message: 'Unauthorized'
{% endvalidation %}
<!-- vale on -->

Now, remove the required `apikey` from the request entirely:

<!-- vale off -->
{% validation request-check %}
  url: /anything
  method: POST
  headers:
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $OPENAI_API_KEY'
  body:
    tools:
      - type: mcp
        server_label: gitmcp
        server_url: https://api.githubcopilot.com/mcp/
        require_approval: never
        headers:
          Authorization: Bearer $GITHUB_PAT
    input: How do I use GitHub MCP?
  status_code: 401
  message: 'Unauthorized: No API key found in request'
{% endvalidation %}
<!-- vale on -->