{%- if include.platform == 'universal' -%}
{%- assign az_platform = 'Universal' -%}
{%- else -%}
{%- assign az_platform = 'Kubernetes' -%}
{%- endif -%}
1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Create zone**.
1. Select **{{ az_platform }}**.
1. In the **Name** field, enter `zone-1`.
1. In the **Use token from system account** dropdown menu, select the name under **Autogenerate new system account with the name**.
1. Click **Create system account and issue token**.
1. Copy the generated zone token and export it to your environment:
   ```sh
   export CONTROL_PLANE_TOKEN='YOUR_GENERATED_ZONE_ACCESS_TOKEN'
   ```
1. Run the commands provided in {{site.konnect_short_name}} to deploy the zone control plane.
1. Once the zone is connected, click **Close**.
