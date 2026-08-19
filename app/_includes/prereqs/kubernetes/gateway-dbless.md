Deploy a standalone DB-less {{site.base_gateway}} data plane into the `kong` namespace. The rest of this guide uses the `kong-dp` release and the `values-dp.yaml` file created here.

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Create the `kong` namespace:

   ```bash
   kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -
   ```

1. Create a file named `license.json` containing your {{site.ee_product_name}} license and store it in a Kubernetes secret:

   ```bash
   kubectl create secret generic kong-enterprise-license --from-file=license=./license.json -n kong
   ```

1. Create a `values-dp.yaml` file:

   ```bash
   cat <<EOF > values-dp.yaml
   # Do not use {{site.kic_product_name}}
   ingressController:
     enabled: false

   image:
     repository: kong/kong-gateway
     tag: "{{ site.data.gateway_latest.release }}"

   env:
     # Run without a database
     database: "off"
     LICENSE_DATA:
       valueFrom:
         secretKeyRef:
           name: kong-enterprise-license
           key: license

   # In DB-less mode, {{site.base_gateway}} only reports itself ready once it has
   # built a router, which requires at least one Route in the declarative config.
   dblessConfig:
     config: |
       _format_version: "3.0"
       services:
         - name: example
           url: http://example.internal
           routes:
             - name: example-route
               paths:
                 - /example

   # The data plane handles proxy traffic only
   proxy:
     enabled: true
     # This guide reaches the proxy with kubectl port-forward, so it doesn't
     # need an external address
     type: ClusterIP

   admin:
     enabled: false

   manager:
     enabled: false
   EOF
   ```

1. Install the release and wait for it to become ready:

   ```bash
   helm upgrade --install kong-dp kong/kong -n kong --values ./values-dp.yaml --wait
   ```

1. Confirm that the data plane is running:

   ```bash
   kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp
   ```

   You should see one pod with a `Running` status:

   ```
   NAME                            READY   STATUS    RESTARTS   AGE
   kong-dp-kong-7cfbc49585-2v4qr   1/1     Running   0          45s
   ```
   {:.no-copy-code}
