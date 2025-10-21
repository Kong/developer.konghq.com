To use the audit log webhook, you need a configured SIEM provider. In this tutorial, we'll use SumoLogic, but you can use any SIEM provider that supports the [ArcSight CEF Format](https://docs.centrify.com/Content/IntegrationContent/SIEM/arcsight-cef/arcsight-cef-format.htm) or raw JSON. {{site.konnect_short_name}} supports any HTTP authorization header type.

Before you can push audit logs to your SIEM provider, configure the service to receive logs. 
This configuration is specific to your vendor.

In this tutorial, we'll [configure an HTTPS data collector and source](https://help.sumologic.com/docs/send-data/hosted-collectors/http-source/logs-metrics/#configure-an-httplogs-and-metrics-source) in SumoLogic.

1. In the SumoLogic sidebar, click **Data Management** > **Collection**.
1. Click **Add Collector**.
1. Click **Hosted Collector**.
1. In the **Name** field, enter `Konnect`.
1. When prompted to add a new data source to the collector, click **OK**.
1. Select **HTTP Logs & Metrics**.
1. In the **Name** field, enter `Konnect`.
1. Click **OK**.
1. Copy and export the SumoLogic endpoint URL in terminal:
   ```sh
   export SIEM_ENDPOINT='YOUR-SIEM-HTTP-ENDPOINT'
   ```
1. In the SumoLogic sidebar, click **Administration** > **Account Security Settings** > **Access Keys** to [create an access key](https://help.sumologic.com/docs/manage/security/access-keys/#create-an-access-key).
1. Click **Add Access Key**.
1. In the **Name** field, enter `Konnect`.
1. Click **Save**.
1. Export the access key as an environment variable in your terminal:
   ```sh
   export SIEM_TOKEN='YOUR-ACCESS-KEY'
   ```
1. Click **Done**.

If needed, configure your network's firewall settings to allow traffic through the `8071` TCP or UDP port that {{site.konnect_short_name}} uses for audit logging. See the [Konnect ports and network requirements](/konnect-platform/network/).