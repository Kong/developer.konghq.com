This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
1. Verify the installation:

    ```sh
    kongctl version
    ```

If you're using an existing {{site.ai_gateway}} instead of the quickstart script, adopt it into a kongctl namespace so the apply command later in this tutorial can manage it:

```sh
kongctl adopt ai-gateway "$AI_GATEWAY_ID" \
    --namespace ai-gateway-get-started \
    --pat "$KONNECT_TOKEN"
```