To configure VNET peering in {{site.konnect_short_name}}, you'll need a [virtual network configured in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/quickstart-create-virtual-network?tabs=portal). 

Copy and export the following:
```sh
export VNET_SUBSCRIPTION_ID='YOUR VNET SUBSCRIPTION ID'
export RESOURCE_GROUP_NAME='RESOURCE GROUP NAME FOR YOUR VNET'
export RESOURCE_GROUP_ID='RESOURCE GROUP ID FOR YOUR VNET'
export VNET_NAME='YOUR VNET NAME'
```

{:.danger}
> **Important:** Your Azure virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.