In production, these manifests live in your deployment repository.
In this guide, a local `recovery` directory plays that role.

1. Create the directory:

   ```bash
   mkdir -p recovery
   ```

1. Save a KongService and a KongRoute named `dr-check` that target the `gateway-control-plane` control plane in a single manifest:

   ```bash
   cat <<EOF > recovery/entities.yaml
   kind: KongService
   apiVersion: configuration.konghq.com/v1alpha1
   metadata:
     name: dr-check
     namespace: kong
   spec:
     controlPlaneRef:
       type: konnectNamespacedRef
       konnectNamespacedRef:
         name: gateway-control-plane
     name: dr-check
     protocol: http
     host: httpbin.konghq.com
   ---
   kind: KongRoute
   apiVersion: configuration.konghq.com/v1alpha1
   metadata:
     name: dr-check
     namespace: kong
   spec:
     serviceRef:
       type: namespacedRef
       namespacedRef:
         name: dr-check
     name: dr-check
     paths:
       - /dr-check
     protocols:
       - http
   EOF
   ```

1. Apply the manifest:

   ```bash
   kubectl apply -f recovery/entities.yaml
   ```

1. Wait for {{site.operator_product_name}} to create both entities in {{site.konnect_short_name}}:

   ```bash
   kubectl wait --for=condition=Programmed kongservice/dr-check kongroute/dr-check \
     -n kong --timeout=120s
   ```
