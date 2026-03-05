Now that your Dedicated Cloud Gateway Azure network is ready, you can configure VNET peering to connect your Azure virtual network to your Dedicated Cloud Gateway.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure VNET peering".
1. In the **Tenant ID** field, enter [your Microsoft Entra tenant ID](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
1. In the **Subscription ID** field, enter your virtual network's subscription ID.
1. In the **Resource group name** field, enter your virtual network's resource group name.
1. In the **VNET Name** field, enter your virtual network's name.
1. Click **Next**.
1. Grant access to the Dedicated Cloud Gateway app in Microsoft Entra using the link provided in the setup wizard.
   
   {:.warning}
   > **Important:** You need an admin account to approve the app.
1. Create a peering role with the Azure CLI using the command in the UI wizard.

   {{site.konnect_short_name}} requires permission to create and manage peering resources. You must define a role named `Kong Cloud Gateway Peering Creator` with the following permissions:

    * Read and write access to Virtual Network peering configurations
    * Permission to perform peering actions

1. Assign the role to the service principal so it has permission to peer with your virtual network using the command in the UI wizard.
1. Select **Please confirm if you have completed the above mentioned steps.**
1. Click **Done**.