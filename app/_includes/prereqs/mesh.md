This is a {{site.konnect_short_name}} tutorial and requires a {{site.konnect_short_name}} Plus account/ 
If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. After creating your {{site.konnect_short_name}} account, [create the {{site.mesh_product_name}} Control Plane](https://cloud.konghq.com/us/mesh-manager/create-control-plane) and your first Mesh zone. Follow the instructions in {{site.konnect_short_name}} to deploy your data plane.
    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
2. Set these values as environment variables:
    ```sh
    export KONNECT_TOKEN='YOUR KONNECT TOKEN'
    export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
    export KONNECT_CONTROL_PLANE_ID='5036fd1b-43a6-426f-a595-1b45c4439203'
    ```
