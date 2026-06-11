1. Run the following command to create a sample httpbin Service:

   ```bash
   kubectl apply -f https://developer.konghq.com/manifests/kic/httpbin-service.yaml -n kong
   ```

1. Create an `HTTPRoute` resource:

   ```sh
   echo '
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: httpbin-route
     namespace: kong
     annotations:
       konghq.com/strip-path: "true"
   spec:
     parentRefs:
       - name: kong
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /httpbin
         backendRefs:
           - name: httpbin
             kind: Service
             port: 80' | kubectl apply -f -
   ```
