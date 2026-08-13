You need a [{{site.konnect_short_name}} system account token](https://cloud.konghq.com/global/organization/system-accounts/) (`spat_`) with the **Entitlement Access** role for Metering.
This role grants the permission to query entitlement access information for the {{site.metering_and_billing}} Entitlement Access API. This token authenticates the Entitlement Enforcement plugin when it checks customer access.

This is a different token from the **Ingest** token used by the {{site.metering_and_billing}} plugin: ingesting events and querying entitlement access are separate permissions.

Export your system account token:

```sh
export DECK_ENTITLEMENT_ACCESS_TOKEN='YOUR SPAT TOKEN'
```

For more information, see [system accounts and access tokens](/konnect-api/#system-accounts-and-access-tokens).
