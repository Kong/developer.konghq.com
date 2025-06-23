To use the audit log webhook, you need a configured SIEM provider. In this tutorial, we'll use SumoLogic, but you can use any SIEM provider that supports the [ArcSight CEF Format](https://docs.centrify.com/Content/IntegrationContent/SIEM/arcsight-cef/arcsight-cef-format.htm) or raw JSON.

Before you can push audit logs to your SIEM provider, configure the service to receive logs. 
This configuration is specific to your vendor.

1. In SumoLogic, [configure an HTTPS data collection endpoint](https://help.sumologic.com/docs/send-data/hosted-collectors/http-source/logs-metrics/#configure-an-httplogs-and-metrics-source) you can send CEF or raw JSON data logs to. {{site.konnect_short_name}} supports any HTTP authorization header type. 
1. Copy and export the endpoint URL:
   ```sh
   export SIEM_ENDPOINT='YOUR-SIEM-HTTP-ENDPOINT'
   ```

1. [Create an access key](https://help.sumologic.com/docs/manage/security/access-keys/#create-an-access-key) in SumoLogic. Export the access key as an environment variable:
   ```sh
   export SIEM_TOKEN='YOUR-ACCESS-KEY'
   ```

1. Configure your network's firewall settings to allow traffic through the `8071` TCP or UDP port that {{site.konnect_short_name}} uses for audit logging. See the [Konnect ports and network requirements](/konnect-platform/network/).