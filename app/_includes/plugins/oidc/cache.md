If {{site.base_gateway}} successfully authenticates with Keycloak, you'll see a `200` response with your bearer token in the Authorization header.

If you make another request using the same credentials, you'll see that {{site.base_gateway}} adds less latency to the request because it has cached the token endpoint call to Keycloak:

```
X-Kong-Proxy-Latency: 25
```
{:.no-copy-code}