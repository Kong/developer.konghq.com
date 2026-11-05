1. Generate an EC P-256 key pair:

   ```sh
   openssl ecparam -name prime256v1 -genkey -noout | openssl pkcs8 -topk8 -nocrypt -out vault-private.pem
   openssl pkey -in vault-private.pem -pubout -out vault-public.pem
   ```

1. Export the private key as a single line, so the data plane can read it when it starts:

   ```sh
   export TOKEN_VAULT_PRIVATE_KEY=$(grep -v -- '-----' vault-private.pem | tr -d '\n')
   ```
