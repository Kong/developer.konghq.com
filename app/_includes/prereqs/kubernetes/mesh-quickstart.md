1. Install {{site.mesh_product_name}}:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   helm upgrade \
     --install \
     --create-namespace \
     --namespace kong-mesh-system \
     kong-mesh kong-mesh/kong-mesh
   kubectl wait -n kong-mesh-system --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
   ```

1. Apply the demo configuration:
   {% capture demo %}
   {% include prereqs/kubernetes/mesh-demo.md %}
   {% endcapture %}
   {{demo | indent: 3}}
