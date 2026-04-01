1. Run the following command to create a sample echo Service:

   ```bash
   kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
   ```

1. Create an `HTTPRoute` resource:

   ```sh
   echo '
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: echo-route
     namespace: kong
   spec:
     parentRefs:
       - name: kong
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /echo
         backendRefs:
           - name: echo
             kind: Service
             port: 1027' | kubectl apply -f -
   ``` 