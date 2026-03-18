You can use a Dedicated Cloud [control plane group](/gateway/control-plane-groups/) to isolate the Gateway configuration by team while still sharing a Dedicated Cloud Gateway cluster. 

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **New**.
1. Select **New control plane group**.
1. In the **Name** field, enter `dcgw-control-plane-group`.
1. From the **Control Planes** dropdown menu, select `hybrid-cp`. 
1. For the Node Type, select **Dedicated Cloud**.
1. Click **Save**.
1. Click **Configure data plane**.
1. From the **Provider** dropdown menu, select "{{include.provider}}".
1. From the **Region** dropdown menu, select the region you want to configure the cluster in. 
1. Edit the Network range as needed.
   
   {:.danger}
   > **Important:** Your {{include.provider}} virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.
1. From the **Access** dropdown menu, select "Public" or "Private".
1. Click **Create data plane node**.
1. Click **Go to overview**.

   {:.warning}
   > **Important:** Wait until your {{include.provider}} network displays as `Ready` before proceeding to the next step.

1. Copy and export the ID of the control plane group you want to configure the managed cache for:
   ```sh
   export CONTROL_PLANE_GROUP_ID='YOUR CONTROL PLANE GROUP ID'
   ```