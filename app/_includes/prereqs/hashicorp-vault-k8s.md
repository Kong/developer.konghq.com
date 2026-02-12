1. Install Vault in `dev` mode. **This is not recommended for production deployments**:

   ```bash
   helm install vault hashicorp/vault \
     --set='server.dev.enabled=true' \
     --namespace vault \
     --create-namespace
   ```

1. Create a secret in HashiCorp Vault:

   ```bash
   kubectl exec -it -n vault vault-0 -- \
     vault kv put secret/customer/acme name="ACME Inc."
   ```