This is a Konnect tutorial that requires Dedicated Cloud Gateways access.

If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. The following Konnect items are required to complete this tutorial:
    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
    * Dedicated Cloud Gateway Control Plane: You can use an existing Dedicated Cloud Gateway or [create a new one](https://cloud.konghq.com/gateway-manager/create-gateway) to use for this tutorial.
    * Network ID: The default Dedicated Cloud Gateway network ID can be found in **API Gateway** > **Network**

2. Set these values as environment variables:

    ```sh
    export KONNECT_TOKEN='YOUR KONNECT TOKEN'
    export KONNECT_NETWORK_ID='KONNECT NETWORK ID'
    ```