This is a {{site.konnect_short_name}} tutorial and requires a {{site.konnect_short_name}} Plus account. 
If you don't have a {{site.konnect_short_name}} account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. After creating your {{site.konnect_short_name}} account, [create the {{site.mesh_product_name}} Control plane](https://cloud.konghq.com/us/mesh-manager/create-control-plane) and your first Mesh zone. Follow the instructions in {{site.konnect_short_name}} to deploy your data plane.

2. The {{site.konnect_short_name}} onboarding process will guide you through the steps below, automatically injecting you System Access Token, Control plane URL and Control plane ID. If you want to follow the steps here, export the generated token, Control plane URL and Control plane ID:
    ```sh
    export KONNECT_TOKEN='YOUR KONNECT TOKEN'
    export KONNECT_CONTROL_PLANE_URL='YOUR KONNECT CONTROL PLANE'
    export KONNECT_CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
    ```
