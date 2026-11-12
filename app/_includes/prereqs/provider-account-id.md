In order to manage Cloud Gateway Networks you need to have a Cloud Gateway Provider Account associated with your {{site.konnect_short_name}} account. Export the ID of your provider account to your environment with the [Cloud Gateways API](/api/konnect/cloud-gateways/#/operations/list-provider-accounts):

```sh
export CLOUD_GATEWAY_PROVIDER_ID=$(curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $KONNECT_TOKEN" -XGET https://global.api.konghq.com/v2/cloud-gateways/provider-accounts | jq -r '.data[0].id')
```
{: data-test-prereq="block" }