{% capture details_content %}
1. Add the Kong Mesh Helm charts:

   ```bash
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   ```

1. Install {{ site.mesh_product_name }} using Helm:

   ```bash
   helm upgrade --install --create-namespace --namespace kong-mesh-system kong-mesh kong-mesh/kong-mesh --wait 
   ```
   {: data-test-prereq="block" }

{% endcapture %}
{% include how-tos/prereq_cleanup_item.html summary="Install Kong Mesh" details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}
