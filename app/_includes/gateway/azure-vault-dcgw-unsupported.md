{:.warning}
> **Dedicated Cloud Gateway limitations:**
* Azure Key Vault **is not** supported as a Vault backend on Dedicated Cloud Gateways: Since the client secret has no Vault entity equivalent, it can only be set through this environment variable (or the `credentials_prefix` variant). Dedicated Cloud Gateways only accept `KONG_` and `OTEL_` prefixed [environment variables](/dedicated-cloud-gateways/reference/#kong-gateway-configuration), so `AZURE_CLIENT_SECRET` can't be set. 
> * Azure managed identity **is not** supported on Dedicated Cloud Gateways.
