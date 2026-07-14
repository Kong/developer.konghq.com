This tutorial uses a Claude model deployed on Azure AI Foundry. Azure AI Foundry serves Claude models through a native Anthropic-compatible endpoint, not the Azure OpenAI API, so you need a Foundry resource with a Claude model deployment rather than an Azure OpenAI resource.

1. [Create an Azure AI Foundry resource](https://ai.azure.com/) if you don't already have one.
1. In the Azure AI Foundry portal, go to **Model catalog**, find a Claude model (for example, **Claude Sonnet 4.6**), and deploy it.
    1. Note the deployment name you choose, you'll reference it later.
1. Once deployed, export the following environment variables:

    ```sh
    export AZURE_AI_FOUNDRY_TOKEN='YOUR_AZURE_AI_FOUNDRY_API_KEY'
    export AZURE_AI_FOUNDRY_UPSTREAM_URL='https://YOUR_RESOURCE_NAME.services.ai.azure.com/anthropic'
    ```

    {:.warning}
    > `AZURE_AI_FOUNDRY_UPSTREAM_URL` must end at `/anthropic`. Do not append `/v1/messages`. {{site.ai_gateway}} appends the rest of the Anthropic Messages API path automatically.
