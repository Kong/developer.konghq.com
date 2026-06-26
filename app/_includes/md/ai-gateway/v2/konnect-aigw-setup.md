To create a new Gateway using Konnect:

1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
1. Export your token to an environment variable:

   ```bash
   export KONNECT_TOKEN='YOUR_KONNECT_PAT'
   ```
1. Run the {{site.ai_gateway}} [quickstart script](https://get.konghq.com/quickstart/ai) to automatically provision a Control Plane in {{site.konnect_product_name}} and a local Data Plane:

   ```bash
   curl -Ls https://get.konghq.com/quickstart/ai | bash -s -- -k $KONNECT_TOKEN
   ```

This sets up a {{site.ai_gateway}} Control Plane named `ai-quickstart`, provisions a local Data Plane, and prints out the following environment variables export:

```bash
export AI_GATEWAY_ID=your-gateway-id
export DECK_KONNECT_TOKEN=$KONNECT_TOKEN
export DECK_KONNECT_CONTROL_PLANE_NAME=quickstart
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
export KONNECT_PROXY_URL='http://localhost:8000'
```

Copy and paste these into your terminal to configure your session.