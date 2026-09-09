You need a [{{site.konnect_short_name}} system account token](https://cloud.konghq.com/global/organization/system-accounts/) (`spat_`) with the **Ingest** role for Metering.
This token authenticates the Metering & Billing plugin when it sends events to the {{site.konnect_short_name}} ingest endpoint.

Export your system account token:

```sh
export AUTH_TOKEN='YOUR SPAT TOKEN'
```

For more information, see [system accounts and access tokens](/konnect-api/#system-accounts-and-access-tokens).
