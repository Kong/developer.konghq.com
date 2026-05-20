1. Port-forward the `demo-app` service on port `5050`:

   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5050:5050
   ```

1. In a new terminal, send a request to `demo-app`:

   ```sh
   curl -XPOST localhost:5050/api/counter
   ```

   You should see an error like this:

   ```json
   {
     "instance": "d11ee97a4b45ff3a7b59091d1612b7f7",
     "status": 500,
     "title": "failed to retrieve zone",
     "type": "https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"
   }
   ```
   {:.no-copy-code}

{% include mesh/meshidentity/mtls-explanation.md %}
