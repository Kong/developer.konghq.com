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
1. Create a peering role with the Azure CLI:
   ```sh
   az role definition create --output none --role-definition '{
       "Name": "Kong Cloud Gateway Peering Creator - Kong",
       "Description": "Perform cross-tenant network peering.",
       "Actions": [
           "Microsoft.Network/virtualNetworks/read",
           "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
           "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
           "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
           "Microsoft.Network/virtualNetworks/peer/action"
       ],
       "AssignableScopes": [
           "/subscriptions/$VNET_SUBSCRIPTION_ID",
       ]
   }'
   ```

   {{site.konnect_short_name}} requires permission to create and manage peering resources. You must define a role named `Kong Cloud Gateway Peering Creator` with the following permissions:

    * Read and write access to Virtual Network peering configurations
    * Permission to perform peering actions

    Use the Azure CLI to define the role, replacing `$VNET_SUBSCRIPTION_ID` with your Azure subscription ID.
1. Assign the role to the service principal so it has permission to peer with your virtual network:
   ```sh
   az role assignment create \
     --role "Kong Cloud Gateway Peering Creator - Kong" \
     --assignee "$(az ad sp list --filter "appId eq '207b296f-cf25-4d23-9eba-9a2c41dc62ca'" \
     --output tsv --query '[0].id')" \
     --scope "/subscriptions/$VNET_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME"
   ```
1. Select **Please confirm if you have completed the above mentioned steps.**
1. Click **Done**.