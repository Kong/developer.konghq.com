In production, these manifests live in your deployment repository.
In this guide, a local `recovery` directory plays that role.

1. Create the directory:

   ```bash
   mkdir -p recovery
   ```

1. Save the `kong` namespace, a GatewayConfiguration, a GatewayClass, a Gateway, and an HTTPRoute that sends `/echo` to the echo Service in a single manifest:

   ```bash
   cat <<EOF > recovery/resources.yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: kong
   ---
   kind: GatewayConfiguration
   apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
   metadata:
     name: kong-configuration
     namespace: kong
   spec:
     dataPlaneOptions:
       deployment:
         podTemplateSpec:
           spec:
             containers:
             - name: proxy
               image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
   ---
   kind: GatewayClass
   apiVersion: gateway.networking.k8s.io/v1
   metadata:
     name: kong
   spec:
     controllerName: konghq.com/gateway-operator
     parametersRef:
       group: gateway-operator.konghq.com
       kind: GatewayConfiguration
       name: kong-configuration
       namespace: kong
   ---
   kind: Gateway
   apiVersion: gateway.networking.k8s.io/v1
   metadata:
     name: kong
     namespace: kong
   spec:
     gatewayClassName: kong
     listeners:
     - name: http
       protocol: HTTP
       port: 80
   ---
   kind: HTTPRoute
   apiVersion: gateway.networking.k8s.io/v1
   metadata:
     name: echo
     namespace: kong
   spec:
     parentRefs:
       - group: gateway.networking.k8s.io
         kind: Gateway
         name: kong
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /echo
         backendRefs:
           - name: echo
             port: 1027
   ---
   EOF
   ```

1. Add the echo application to the same manifest:

   ```bash
   curl -fsSL {{site.links.web}}/manifests/kic/echo-service.yaml >> recovery/resources.yaml
   ```

1. Apply the manifest:

   ```bash
   kubectl apply -n kong -f recovery/resources.yaml
   ```

1. Wait for {{site.operator_product_name}} to program the Gateway:

   ```bash
   kubectl wait --for=condition=Programmed gateway/kong -n kong --timeout=300s
   ```
