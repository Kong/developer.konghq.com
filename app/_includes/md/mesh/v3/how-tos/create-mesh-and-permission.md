{%- assign kubectl_context = '' -%}{%- if include.kube_context %}{% assign kubectl_context = ' --context ' | append: include.kube_context %}{% endif -%}
1. Confirm that `kongctl` can reach the global control plane:

   ```sh
   kongctl get mesh resource-types --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   ```

1. Create a new `konnect-demo` mesh and a demo identity provider on the global control plane:

   ```sh
   cat <<'EOF' | kongctl apply mesh -f - --control-plane-id "$CONTROL_PLANE_ID" \
     --base-url "https://$KONNECT_REGION.api.konghq.com" --pat "$KONNECT_TOKEN"
   type: Mesh
   name: konnect-demo
   ---
   type: MeshIdentity
   mesh: konnect-demo
   name: demo-identity
   spec:
     selector:
       dataplane: {}
     spiffeID:
       trustDomain: konnect-demo.mesh.local
     provider:
       type: Bundled
       bundled:
         autogenerate:
           enabled: true
         insecureAllowSelfSigned: true
         meshTrustCreation: Enabled
   EOF
   ```

   [`MeshIdentity`](/mesh/policies/meshidentity/) issues certificates and publishes their CA in `MeshTrust`. This example accepts
   a generated self-signed CA for the demo; review your production PKI requirements before reusing
   it.

1. Wait for the identity to be ready and for the trust to be generated:

   ```sh
   kongctl get mesh meshidentities demo-identity --mesh konnect-demo -o yaml \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   kongctl get mesh meshtrusts --mesh konnect-demo \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   ```

1. Confirm that the new mesh has synced to the Kubernetes zone:

   ```sh
   kubectl{{ kubectl_context }} get mesh konnect-demo
   ```

1. Apply a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) to the zone to allow the `client` ServiceAccount to call the `server` workload:

   ```sh
   cat <<'EOF' | kubectl{{ kubectl_context }} apply -f -
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: client-to-server
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: konnect-demo
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: Dataplane
       labels:
         app: server
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Exact
                 value: spiffe://konnect-demo.mesh.local/ns/kong-mesh-demo/sa/client
   EOF
   ```
