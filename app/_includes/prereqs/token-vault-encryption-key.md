Token Vault [encrypts every credential it stores](/identity/token-vault/#credential-storage-and-encryption) with a public key that you register. The matching private key stays on the {{site.ai_gateway}} data plane, so {{site.identity}} can't decrypt your users' credentials.

1. Generate an EC P-256 key pair:

   ```sh
   openssl ecparam -name prime256v1 -genkey -noout | openssl pkcs8 -topk8 -nocrypt -out vault-private.pem
   openssl pkey -in vault-private.pem -pubout -out vault-public.pem
   ```

1. Export the private key as a single line, so the data plane can read it when it starts:

   ```sh
   export TOKEN_VAULT_PRIVATE_KEY=$(grep -v -- '-----' vault-private.pem | tr -d '\n')
   ```

1. Export the public key, with the newlines escaped so it fits in a JSON body:

   ```sh
   export VAULT_PUBLIC_KEY=$(awk 'NF {printf "%s\\n", $0}' vault-public.pem)
   ```

1. Register the public key as a vault key:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: my-vault-key
  public_key: $VAULT_PUBLIC_KEY
capture:
  - variable: VAULT_KEY_ID
    jq: ".id"
  - variable: VAULT_KEY_KID
    jq: ".kid"
{% endkonnect_api_request %}
<!--vale on-->
