After your Azure private networking configuration is ready in {{site.konnect_short_name}}, you can configure private DNS.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private DNS".
1. Click **Private hosted zone**.
1. In the **Name** field, enter the fully qualified domain name for your private hosted zone in Azure.
1. In the **Tenant ID** field, enter your [tenant ID from Microsoft Entra](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
1. In the **Subscription ID** field, enter the subscription ID for your private DNS zone.
1. In the **Resource group ID** field, enter the resource group ID that your private DNS zone is in.
1. In the **Virtual network link name** field, enter the name of the virtual network link.
1. In the **Private DNS zone name** field, enter the name of your private DNS zone in Azure.
1. Create a DNS link creator role with the Azure CLI using the command in the UI wizard.
1. Assign the role to the service principal with the Azure CLI using the command in the UI wizard.
1. [Link your private DNS zone to your virtual network](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#link-the-virtual-network) using the command provided by the private DNS wizard in the UI.
1. Select **I confirm that I completed all required steps and understand that incorrect configuration can cause DNS resolution issues.**
1. Click **Connect**.