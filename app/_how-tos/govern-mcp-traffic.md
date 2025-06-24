---
title: "Part 1: Secure MCP traffic with the Key Authentication plugin"
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advance/
  - text: Key Auth plugin
    url: /plugins/key-auth/

description: Learn how to secure MCP traffic within GitHub remote MCP server with the Key Authentication plugin

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

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

tldr:
  q: How can I secure my MCP traffic using {{ site.base_gateway }}?
  a: |
    Enable the Key Authentication plugin on your MCP service and require API keys from Consumers. Kong AI Gateway then enforces these keys on all incoming MCP requests, ensuring secure, authorized access.

    {:.info}
    > For further authentication of your MCP traffic you can also use [The OpenID Connect](https://developer.konghq.com/plugins/openid-connect/) (OIDC) plugin lets you integrate Kong Gateway with an identity provider (IdP), or you can extend plugins to support fine-grained Authorization models via JWT claims or declarative [Access Control Lists](https://developer.konghq.com/plugins/acl/) (ACLs)


tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: GitHub
      content: |
        To complete this tutorial, you'll need access to GitHub, access to GitHub repository and [Github Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

        Once you've created your Github Personal Access Token, make sure to export it as an environment variable by running the following command:

        ```bash
        export GITHUB_PAT=<YOUR_GITHUB_TOKEN>
        ```
      icon_url: assets/third-party/github.svg
    - title: Entities
      content: |
        For this tutorial, you’ll need Kong Gateway entities, like Gateway Services and Routes, pre-configured. These entities are essential for Kong Gateway to function but installing them isn’t the focus of this guide. Follow these steps to pre-configure them:


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---