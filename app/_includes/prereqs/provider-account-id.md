In order to mange Cloud Gateway Networks you need to have a Cloud Gateway Provider Account associated with your {{site.konnect_short_name}} account. You can obtain the ID to your provider account using the [Cloud Gateways API](/api/konnect/cloud-gateways/#/operations/list-provider-accounts). 

```sh
curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $KONNECT_TOKEN" -XGET https://global.api.konghq.com/v2/cloud-gateways/provider-accounts | jq
```

Export the value of the `id` field to your environment: 

```sh
export CLOUD_GATEWAY_PROVIDER_ID='YOUR PROVIDER ID'
```