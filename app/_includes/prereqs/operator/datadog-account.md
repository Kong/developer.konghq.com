To install Datadog agents in your cluster you will need:
* An [API key](https://docs.datadoghq.com/account_management/api-app-keys/#api-keys)
* An [application key](https://docs.datadoghq.com/account_management/api-app-keys/#application-keys)
* The Datadog site for your region (for example `datadoghq.com` for the US1 region or `datadoghq.eu` for the EU region).

Export these to your environment:

```bash
export DD_SITE='YOUR DATADOG SITE'
export DD_API_KEY='YOUR DATADOG API KEY'
export DD_APP_KEY='YOUR DATADOG APPLICATION KEY'
```
