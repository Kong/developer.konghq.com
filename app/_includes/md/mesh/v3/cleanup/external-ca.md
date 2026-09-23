Remove only the resources for the provider you followed.

1. If you followed the `Bundled` provider, delete the identity and the CA material you handed it:

   ```sh
   kubectl delete meshidentity flight-operations-id -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete secret kong-air-external-ca-cert kong-air-external-ca-key -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete certificate kong-air-mesh-ca -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete secret kong-air-mesh-ca-tls -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete clusterissuer selfsigned-issuer --ignore-not-found
   ```

1. If you followed the cert-manager extension, delete the identity and the issuer chain:

   ```sh
   kubectl delete meshidentity kong-air-certmanager-identity -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete issuer kong-air-mesh-ca-issuer -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete certificate kong-air-mesh-ca -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete secret kong-air-mesh-ca-secret -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete clusterissuer selfsigned-issuer --ignore-not-found
   ```

1. Restart the workloads so they pick up certificates from `kong-air-identity` again:

   ```sh
   kubectl rollout restart deployment -n kong-air-production
   ```

1. If you installed cert-manager only for this guide, remove it. Skip this if anything else in the cluster uses it:

   ```sh
   kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml
   ```
