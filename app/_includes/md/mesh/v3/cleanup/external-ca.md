Remove only the resources for the provider you followed.

1. Restore the `MeshTrafficPermission` to the default trust domain. Do this first, so `check-in-api` keeps accepting traffic once `flight-control` falls back to the mesh-wide identity:

   ```bash
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: allow-flight-control-to-check-in
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: Dataplane
       labels:
         app: check-in-api
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Exact
                 value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
   EOF
   ```

1. If you followed the `Bundled` provider, delete the identity and the CA material you handed it:

   ```sh
   kubectl delete meshidentity flight-operations-id -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshtrust flight-operations-id -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete secret kong-air-external-ca-cert kong-air-external-ca-key -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete certificate kong-air-mesh-ca -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete secret kong-air-mesh-ca-tls -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete clusterissuer selfsigned-issuer --ignore-not-found
   ```

1. If you followed the cert-manager extension, delete the identity and the issuer chain:

   ```sh
   kubectl delete meshidentity kong-air-certmanager-identity -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshtrust kong-air-certmanager-identity -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete secret kong-air-certmanager-trust -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete issuer kong-air-mesh-ca-issuer -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete certificate kong-air-certmanager-ca -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete secret kong-air-certmanager-ca-tls -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete clusterissuer selfsigned-issuer --ignore-not-found
   ```

   {:.info}
   > Generated `MeshTrust` resources are owned by the `Mesh`, not by the `MeshIdentity`, so they are not garbage collected when you delete the identity. Delete them explicitly, otherwise the mesh keeps trusting a CA that no longer issues anything.

1. Confirm the workloads fell back to the mesh-wide identity. This happens over xDS within a few seconds, with no restart:

   ```sh
   FLIGHT_POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
   kubectl get dataplaneinsight "$FLIGHT_POD" -n kong-air-production -o jsonpath='{.status.mTLS.issuedBackend}{"\n"}'
   ```

   Expected output:

   ```text
   kri_mid_kong-air-mesh_zone1_kong-mesh-system_kong-air-identity_
   ```
   {:.no-copy-code}

1. If you installed cert-manager only for this guide, remove it. Skip this if anything else in the cluster uses it:

   ```sh
   kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml
   ```
