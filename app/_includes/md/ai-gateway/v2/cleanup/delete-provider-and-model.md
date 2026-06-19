Delete the Model entity first. Replace `$MODEL_ID` with the ID returned when you created the model:

```sh
curl --request DELETE \
  --url https://us.api.konghq.com/v1/ai-gateways/$AI_GW_ID/models/$MODEL_ID \
  --header 'Accept: application/problem+json' \
  --header "Authorization: Bearer $KONNECT_TOKEN" \
  --header 'Content-Type: application/json'
```

Then delete the Provider entity. Replace `$PROVIDER_ID` with the ID returned when you created the provider:

```sh
curl --request DELETE \
  --url https://us.api.konghq.com/v1/ai-gateways/$AI_GW_ID/providers/$PROVIDER_ID \
  --header 'Accept: application/problem+json' \
  --header "Authorization: Bearer $KONNECT_TOKEN" \
  --header 'Content-Type: application/json'
```
