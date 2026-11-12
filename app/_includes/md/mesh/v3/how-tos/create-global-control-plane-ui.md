1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **Create a service mesh**.
1. In the **Name** field, enter `example-cp`.
1. From the **Version** dropdown menu, select "v3".
1. Click **Save**.
1. Copy the control plane ID and export it:

   ```sh
   export CONTROL_PLANE_ID='YOUR_CONTROL_PLANE_ID'
   ```
1. Export your {{site.konnect_short_name}} region:

   ```sh
   export KONNECT_REGION='us'
   ```
