---
title: Configure a custom LLM URL in Insomnia
permalink: /how-to/configure-custom-llm-url/

content_type: how_to

products:
- insomnia

description: Configure a custom OpenAI-compatible LLM endpoint to power AI features in Insomnia.
tags:
- mock-servers
- ai
- llm
breadcrumbs:
  - /insomnia/

prereqs:
  inline:
  - title: OpenAI-compatible LLM endpoint
    content: |
      Your LLM service must be running, reachable, and conform to the OpenAI API specification.

      The endpoint must have at least one model available. Insomnia retrieves available models during configuration.

      {:.info}
      > Performance and response quality depend on the model and infrastructure that you provide.

    icon_url: /assets/icons/code.svg


related_resources:
  - text: Mocks
    url: /insomnia/mock-servers/
  - text: Self-hosted mocks
    url: /insomnia/self-hosted-mocks/
  - text: AI in Insomnia
    url: /insomnia/ai-in-insomnia/  
tldr:
  q: How do I configure a custom LLM url in Insomnia?
  a: Open **Preferences** > **AI Settings**, select **LLM URL**, enter your OpenAI-compatible endpoint, load available models, and select the model that you want to use.
---

Insomnia allows you to configure a custom Large Language Model (LLM) endpoint for AI-powered features.

## Configure the custom LLM URL

1. Open **Insomnia**.
1. Click **Preferences**.
1. Select the **AI Settings** tab.
1. From **Activate an LLM**, click **LLM URL**.
1. In the **URL** field, enter your OpenAI-compatible endpoint.
1. Click **Load Models**.
1. From the dropdown list, select a model.
1. Click **Activate**.


Insomnia sends API requests to the configured endpoint.

## Validate

1. From a **Document**, click **Generate Mock**.
1. Select your configured **LLM URL** provider.
1. Complete the **Create a new Mock Server** form.

   {:.info}
   > You must enable **Dynamic Responses**.

1. Click **Create**.
1. Select your mock server.
1. Select an API call and click **Test**.

Insomnia sends the request to your custom endpoint instead of a hosted provider.