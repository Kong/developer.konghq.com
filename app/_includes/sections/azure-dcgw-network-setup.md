1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. From the **New** dropdown menu, select "New API gateway".
1. Select **Dedicated Cloud**.
1. In the **Gateway name** field, enter `Azure`.
1. Click **Create and configure**.
1. From the **Provider** dropdown menu, select "Azure".
1. From the **Region** dropdown menu, select the region you want to configure the cluster in. 
1. Edit the Network range as needed.
   
   {:.danger}
   > **Important:** Your Azure virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.
1. From the **Access** dropdown menu, select "Public" or "Private".
1. Click **Create data plane node**.

{:.warning}
> **Important:** Wait until your Azure network displays as `Ready` before proceeding to the next step.