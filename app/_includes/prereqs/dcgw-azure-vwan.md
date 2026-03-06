To configure virtual hub peering in {{site.konnect_short_name}}, you'll need:
* A [virtual network configured in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/quickstart-create-virtual-network?tabs=portal) that is associated with a [virtual WAN](https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-site-to-site-portal#openvwan)
* A [virtual hub](https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-site-to-site-portal#hub) associated with your virtual WAN

Copy your virtual WAN subscription ID, resource group name, and virtual WAN name.

{:.danger}
> **Important:** Your Azure virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited. The Azure virtual network and virtual WAN must also use CIDRs that don't overlap.