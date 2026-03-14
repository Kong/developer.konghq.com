This tutorial uses Azure OpenAI service. Use the following steps to configure it:
1. [Create an Azure account](https://azure.microsoft.com/en-us/get-started/azure-portal).
1. In the Azure Portal, click Create a resource.
    1. Search for Azure OpenAI and select **Azure OpenAI Service**.
    1. Configure your Azure resource.
    1. Once created, export the following environment variable:

        ```sh
        export DECK_AZURE_INSTANCE_NAME='YOUR AZURE RESOURCE NAME'
        ```

2. Once you've created your Azure resource, go to [Azure AI foundry](https://ai.azure.com/) and do the following:
    1. In the **My assets** subgroup in the main sidebar, click **Models and deployments** and click **Deploy model**.
    2. Once deployed, export the following environment variables:

        ```sh
        export DECK_AZURE_OPENAI_API_KEY='YOUR AZURE OPENAI MODEL API KEY'
        export DECK_AZURE_DEPLOYMENT_ID='YOUR AZURE OPENAI DEPLOYMENT NAME'
        ```