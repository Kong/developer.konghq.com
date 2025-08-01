## Generate a token for the client

The Gateway Service requires an access token from the client to access the Service. Generate a token for the client by making a call to the issuer URL:

<!--vale off-->
```sh
curl -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=my-scope"
```
<!--vale on-->

Export your access token:
```sh
export ACCESS_TOKEN='YOUR-ACCESS-TOKEN'
```