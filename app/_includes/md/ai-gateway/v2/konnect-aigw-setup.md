To create a new {{site.ai_gateway}} using {{site.konnect_short_name}}, do the following:

1. Create a new personal access token from the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) by selecting **Generate Token**.
1. Export your token as an environment variable:

   ```bash
   export KONNECT_TOKEN='YOUR_KONNECT_PAT'
   ```
1. Run the {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) to automatically provision a control plane in {{site.konnect_product_name}} and a local data plane:

   ```bash
   curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
   ```

This sets up a {{site.ai_gateway}} control plane named `ai-quickstart`, provisions a local data plane, and prints out the following environment variables export:

```bash
export AI_GATEWAY_ID=your-gateway-id
export DECK_KONNECT_TOKEN=$KONNECT_TOKEN
export DECK_KONNECT_CONTROL_PLANE_NAME=quickstart
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
export KONNECT_PROXY_URL='http://localhost:8000'
```

Copy and paste these into your terminal to configure your session.