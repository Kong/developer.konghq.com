---
title: "Secure GitHub MCP Server traffic with {{ site.base_gateway }} and AI Gateway"
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advance/
  - text: Key Auth plugin
    url: /plugins/key-auth/

permalink: /mcp/secure-mcp-traffic

description: Learn how to secure MCP traffic within GitHub remote MCP server with the Key Authentication plugin

series:
    id: mcp-traffic
    position: 1

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

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How can I secure my MCP traffic using {{ site.base_gateway }}?
  a: |
    Enable the Key Authentication plugin on your MCP service and require API keys from Consumers. Kong AI Gateway then enforces these keys on all incoming MCP requests, ensuring secure, authorized access.

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

To set up AI Proxy with OpenAI, specify the [model](https://platform.openai.com/docs/models) and set the appropriate authentication header. To make requests to a GitHub-hosted remote MCP server, we use the OpenAI `/responses` API endpoint, which is supported natively by Kong AI Gateway. This approach gives you conversational control over your Git repositories while adding a robust security layer through Kong AI Gateway’s capabilities.

Using OpenAI’s `/responses` endpoint with Kong AI Gateway simplifies integration with remote MCP servers in agentic applications. Instead of routing each tool invocation through your backend, the gateway forwards model-generated requests directly to the MCP server. That server exposes standardized tools, which we’ll explore in the next tutorial in this series. By supporting the OpenAI `/responses` API, Kong AI Gateway removes the need for custom glue code and enables direct, low-latency model-to-server calls.


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
  url: /anything/v1/responses
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
  url: /anything/v1/responses
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
    input: how do i use github mcp
  status_code: 400
  message: 'Unauthorized'
{% endvalidation %}
<!-- vale on -->

Now, remove the required `apikey` from the request entirely:

<!-- vale off -->
{% validation request-check %}
  url: /anything/v1/responses
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
    input: how do i use github mcp
  status_code: 401
  message: 'Unauthorized: No API key found in request'
{% endvalidation %}
<!-- vale on -->