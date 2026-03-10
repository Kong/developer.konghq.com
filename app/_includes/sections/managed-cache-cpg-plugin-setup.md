To demonstrate how you can use a managed cache in a Redis-supported plugin, let's apply this configuration to a Rate Limiting Advanced plugin.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Plugins**.
1. Click **New plugin**.
1. Select **Rate Limiting Advanced**.
1. In the **Rate Limit Window Type** fields, enter `100` and `3600`. 
1. Click **View advanced parameters**.
1. In the **Strategy** dropdown menu, select "redis".
1. In the **Shared Redis Configuration** dropdown menu, select your {{site.konnect_short_name}}-managed configuration.
1. In the **Sync Rate** field, enter `5`.
1. Click **Save**.
1. Repeat steps 1 - 11 for each control plane in your control plane group.

{:.warning}
> **Important:** If you're configuring your plugins with decK, you must include the `konnect-managed` partial [default lookup tag](/deck/gateway/tags/) to ensure the managed cache partial is available. Add the following to your plugin config file:
```yaml
_info:
default_lookup_tags:
  partials:
    - konnect-managed
```