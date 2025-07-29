This tutorial uses Azure OpenAI service:
1. [Create an Azure account](https://azure.microsoft.com/en-us/get-started/azure-portal).
1. In the Azure Portal, click Create a resource.
    - Search for Azure OpenAI and select Azure OpenAI Service.
    - Configure your Azure resource.
    - Once created, export the following environment variable:
        ```sh
        export DECK_AZURE_INSTANCE_NAME='YOUR AZURE RESOURCE NAME'
        ```

1. Once you've created your Azure resource, go to [Azure AI foundry](https://ai.azure.com/).
    - In the **My assets** subgroup in the man sidebar, click **Models and deployments** and click **Deploy model**.
    - Once deployed, export the following environment variables:
        ```sh
        export DECK_AZURE_OPENAI_API_KEY='YOUR AZURE OPENAI MODEL API KEY'
        export DECK_AZURE_DEPLOYMENT_ID='YOUR AZURE OPENAI DEPLOYMENT NAME'
        ```
