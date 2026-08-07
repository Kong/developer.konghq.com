Add a zone to connect a data plane and receive configuration updates.

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Create zone**.
1. Select **{{ include.config_type }}** as the configuration type.
1. In the **Name** field, enter `zone-1`.

   {:.info}
   > The zone name must use lowercase alphanumeric characters or hyphens, and start and end with an alphanumeric character.

1. In the **Token** field, enter your {{site.konnect_short_name}} personal access token.
1. {{ include.deploy_instruction }}

   {{site.konnect_short_name}} automatically provisions a [system account access token](#how-does-a-zone-authenticate-to-the-global-control-plane) for the zone and includes it, along with the control plane ID and address, in the deployment steps. You don't need to create a token manually.
1. Once the zone is connected, click **Continue**.
