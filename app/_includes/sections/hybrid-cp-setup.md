First, you need to create a hybrid control plane. The Dedicated Cloud control plane group aggregates the hybrid control plane's configurations and passes them on to the Dedicated Cloud Gateway data plane nodes.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **New**.
1. Select **New API gateway**.
1. Select **Self-managed**.
1. Select **Docker**.
1. In the **Gateway name** field, enter `hybrid-cp`.
1. Click **Create**.
1. Scroll and click **Set up later**.
1. Copy and export the control plane ID that you'll configure the partial for:
   ```sh
   export CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
   ```