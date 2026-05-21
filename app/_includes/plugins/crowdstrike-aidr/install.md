The {{include.name}} plugin is built from source using the `luarocks` utility bundled with {{site.base_gateway}}.
It depends on the `kong-plugin-crowdstrike-aidr-shared` library, which is included in the same repository.

### Prerequisites

Before installing the plugin, ensure you have the following:

* [CrowdStrike customer account](https://www.crowdstrike.com/en-us/login/) in one of the following clouds: US-1, US-2, or EU-1
* [**AIDR for Agents** Falcon subscription](https://pangea.cloud/docs/aidr/get-started/agents)
* [**AIDR Admin** role](https://pangea.cloud/docs/aidr#roles-and-permissions) assigned to your Falcon user for the current customer account
* HTTP access to AIDR API origins
* A running {{site.base_gateway}} installation

#### Register a Kong Collector in AIDR

Register a collector in the [AIDR console](https://aidr.pangea.cloud) to obtain the API key and base URL required to configure the plugin.

1. In the AIDR console, go to the **Collectors** page.
1. Click **Collector**.
1. Choose **Gateway** as the collector type, select **Kong**, and click **Next**.
1. Configure the collector:
   * **Collector Name**: Enter a descriptive name to appear in dashboards and reports.
   * **Logging**: Select whether to log full prompt and response content, or metadata only.
   * **Policy** *(optional)*: Assign a policy to apply detection rules to traffic. You can select an existing policy, create one on the **Policies** page, or select **No Policy, Log Only** to record activity without applying detection rules.
1. Click **Save** to complete registration.

After saving, open the **Config** tab on the collector details page and copy your **API key** and **AIDR base URL**. 
You'll need these when enabling the plugin.

### Installation steps

The following installation steps install and build the `{{include.plugin_slug}}` plugin and the `crowdstrike-aidr-shared` library.

{:.info}
> **Note**: If you want to set up the [{{include.other_plugin_name}}](/plugins/{{include.other_plugin_slug}}/) plugin at the same time, you can add `{{include.other_plugin_slug}}` to your installation and builds, alongside the other two packages.

{% navtabs 'deployment' %}
{% navtab "Konnect" %}

In {{site.konnect_short_name}} hybrid mode, upload the plugin schema to the control plane and deploy the plugin code to each data plane node using a custom Docker image.

1. Clone the plugin repository:

   ```sh
   git clone https://github.com/crowdstrike/aidr-kong.git
   ```

1. Navigate into the repository:

   ```sh
   cd aidr-kong
   ```

1. Set the credentials in your environment:

   ```sh
   export KONNECT_CP_ID="your-control-plane-id"
   export KONNECT_TOKEN="your-konnect-pat"
   ```

1. Upload the {{include.name}} plugin schema using the [Konnect API](/api/konnect/control-planes/):

   ```sh
   curl -X POST \
     "https://us.api.konghq.com/v2/control-planes/${KONNECT_CP_ID}/core-entities/plugin-schemas" \
     --header "Authorization: Bearer ${KONNECT_TOKEN}" \
     --header "Content-Type: application/json" \
     --data "{\"lua_schema\": $(jq -Rs . kong/plugins/{{include.plugin_slug}}/schema.lua)}"
   ```

   Your control plane ID is visible in the {{site.konnect_short_name}} Gateway Manager URL, or on the control plane's overview page.

1. Build the custom {{site.base_gateway}} image using the Dockerfile in the repository:

   ```sh
   docker build -t kong-aidr-plugins:latest .
   ```

1. Run the image as a {{site.konnect_short_name}} data plane node.

   The cluster certificate, key, and CP/telemetry endpoints are provided by {{site.konnect_short_name}} when you click **Add Data Plane Node** in {{site.konnect_short_name}} API Gateway:

   ```sh
   docker run -d \
     --name kong-aidr-dataplane \
     --restart unless-stopped \
     -e "KONG_ROLE=data_plane" \
     -e "KONG_DATABASE=off" \
     -e "KONG_CLUSTER_MTLS=pki" \
     -e "KONG_CLUSTER_CONTROL_PLANE=YOUR_CP_ENDPOINT:443" \
     -e "KONG_CLUSTER_SERVER_NAME=YOUR_CP_ENDPOINT" \
     -e "KONG_CLUSTER_TELEMETRY_ENDPOINT=YOUR_TELEMETRY_ENDPOINT:443" \
     -e "KONG_CLUSTER_TELEMETRY_SERVER_NAME=YOUR_TELEMETRY_ENDPOINT" \
     -e "KONG_CLUSTER_CERT=/PATH/TO/YOUR_CLUSTER_CERT" \
     -e "KONG_CLUSTER_CERT_KEY=/PATH/TO/YOUR_CLUSTER_CERT_KEY" \
     -e "KONG_LUA_SSL_TRUSTED_CERTIFICATE=system" \
     -e "KONG_KONNECT_MODE=on" \
     -e "KONG_ROUTER_FLAVOR=expressions" \
     -e "KONG_PLUGINS=bundled,{{include.plugin_slug}}" \
     -p 8000:8000 \
     -p 8443:8443 \
     kong-aidr-plugins:latest
   ```

1. Confirm the node appears as connected in the API Gateway UI before proceeding.

{% endnavtab %}
{% navtab "Docker" %}

1. Build a custom {{site.base_gateway}} image with the plugin installed from the source repository:

   ```dockerfile
   FROM kong/kong-gateway:latest

   USER root

   COPY ./kong /kong
   COPY ./kong-plugin-crowdstrike-aidr-*.rockspec /

   RUN luarocks make kong-plugin-crowdstrike-aidr-shared-*.rockspec \
   && luarocks make kong-plugin-{{include.plugin_slug}}-*.rockspec

   ENV KONG_PLUGINS=bundled,{{include.plugin_slug}}

   USER kong

   ENTRYPOINT ["/entrypoint.sh"]
   EXPOSE 8000 8443 8001 8444
   STOPSIGNAL SIGQUIT
   HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
   CMD ["kong", "docker-start"]
   ```

1. Clone the plugin repository:

   ```sh
   git clone https://github.com/crowdstrike/aidr-kong.git
   ```

1. Navigate into the repository:

   ```sh
   cd aidr-kong
   ```

1. Build the image:

   ```sh
   docker build -t kong-plugin-crowdstrike-aidr .
   ```

{:.warning}
> This Dockerfile is purposely abbreviated to show only the plugin installation piece.
To launch {{site.base_gateway}} completely with all dependencies, configuration, and optionally a database, install the plugin `.rockspec` files locally using `luarocks`, then see the [Gateway with Docker Compose installation](/gateway/install/docker/) instructions, adjusting the file by adding `KONG_PLUGINS: bundled,{{include.plugin_slug}}` under `environment`.

{% endnavtab %}
{% navtab "kong.conf" %}

1. Clone the plugin repository:

   ```sh
   git clone https://github.com/crowdstrike/aidr-kong.git
   ```

1. Navigate into the repository:

   ```sh
   cd aidr-kong
   ```

1. Install the shared library dependency:

   ```sh
   luarocks make kong-plugin-crowdstrike-aidr-shared-*.rockspec
   ```

1. Install the {{include.name}} plugin:

   ```sh
   luarocks make kong-plugin-{{include.plugin_slug}}-*.rockspec
   ```

1. In your [`kong.conf`](/gateway/configuration/), append the plugin name to the `plugins` field. Make sure the field isn't commented out:

   ```
   plugins = bundled,{{include.plugin_slug}}
   ```

1. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```

{% endnavtab %}
{% endnavtabs %}
