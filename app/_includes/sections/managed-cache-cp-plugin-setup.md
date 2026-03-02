For control plane managed caches, you don't need to manually configure a Redis partial. After the managed cache is ready, {{site.konnect_short_name}} automatically creates a [Redis partial](/gateway/entities/partial/) configuration for you. [Use the redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to setup Redis-supported plugins by selecting the automatically created {{site.konnect_short_name}}-managed Redis configuration. You can’t use the Redis partial configuration in custom plugins. Instead, use env referenceable fields directly.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Plugins**.
1. Click **New plugin**.
1. Select **Rate Limiting Advanced**.
1. In the **Rate Limit Window Type** fields, enter `100` and `3600`. 
1. Click **View advanced parameters**.
1. In the **Strategy** dropdown menu, select "redis".
1. In the **Shared Redis Configuration** dropdown menu, select your {{site.konnect_short_name}}-managed configuration. For example: `konnect-managed-a188516a-b1a6-4fad-9eda-f9b1be1b7159`
1. In the **Sync Rate** field, enter `5`.
1. Click **Save**.

{:.warning}
> **Important:** If you're configuring your plugins with decK, you must include the `konnect-managed` partial [default lookup tag](/deck/gateway/tags/) to ensure the managed cache partial is available. Add the following to your plugin config file:
```yaml
_info:
default_lookup_tags:
  partials:
    - konnect-managed
```