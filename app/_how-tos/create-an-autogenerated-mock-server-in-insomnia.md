---
title: Create an auto-generated mock server

content_type: how_to

products:
- insomnia

description: Use natural language to auto-generate a mock server in your Insomnia project. This feature is powered by AI and can be disabled.

tags:
- mock-servers

breadcrumbs:
  - /insomnia/
related_resources:
  - text: Mocks
    url: /insomnia/mock-servers/
  - text: Create a mock server from a URL
    url: /how-to/create-an-auto-generated-mock-server-from-a-url-in-insomnia/
tldr:
  q: How do I auto-generate a mock server using natural language?
  a: From the **Mocks** tab in Insomnia, click **+ → Auto Generate**, choose **Natural Language**, enter your prompt, and click **Generate**. To disable AI generation, go to **Preferences → AI Features**.
---

You can create a fully configured mock server in Insomnia using a natural language description. Powered by AI, this feature generates routes, sample responses, and mock configuration from your prompt.

## Create a mock server

1. In your Insomnia project, from the **Mocks** tab, click **+**.
2. Click **Auto Generate**.
3. Select an input type.
4. In the prompt box, enter a description of your mock server.  
   Example: `My API is for products. I want to be able to create, update, delete, get, and list products. Products should have a name, a price, and a quantity.`   
5. Indicate if you mock server uses dynamic responses.
6. (Optional) To add additional files to your prompt, click **+ Add Files**.
7. Click **Create**.

The mock server opens and is ready for testing and editing.

## (Optional) Deactivate AI-generated mock servers

You can deactivate the AI feature:

- In Insomnia, go to **Preferences → AI Features**.
- Toggle off **Enable AI-generated mocks**.

When deactivated, the **Auto Generate** option no longer appears in the mock creation menu. You can still create mocks manually or from a URL.

> {:.info}
> AI generation is optional and fully local to your project. Deactivating the feature removes access to natural language input but does not affect existing mocks.

## Validate and test your mock server

After the mock server is created:

- To send requests and inspect responses, use the **Mock Tester** tab.
- Confirm that the generated endpoints and responses match your expectations.
- Edit the mock server configuration as needed.

---