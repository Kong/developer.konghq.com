This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
1. Verify the installation:

    ```sh
    kongctl version
    ```
1. Adopt your {{site.ai_gateway}} into a kongctl namespace so the apply command later in this tutorial can manage it:

    ```sh
    kongctl adopt ai-gateway "$AI_GATEWAY_ID" \
        --namespace weather-mcp \
        --pat "$KONNECT_TOKEN"
    ```