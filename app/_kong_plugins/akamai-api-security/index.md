---
title: 'Akamai API Security'
name: 'Akamai API Security'
schema_name: 'nonamesecurity'

content_type: plugin

publisher: akamai
description: "Akamai API Security machine learning & prevention blocking for {{site.base_gateway}} discovery"

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true

support_url: https://www.akamai.com/global-services/support

icon: akamai.svg

search_aliases:
  - nonamesecurity-kongtrafficsource
  - noname
  - noname security

related_resources:
  - text: Gateway documentation
    url: /index/gateway/
  - text: Installation guide
    url: https://docs.nonamesecurity.com/docs/kong-plugin
  - text: Performance benchmarking
    url: https://docs.nonamesecurity.com/docs/kong-performance-results

min_version:
  gateway: '2.6'
---

The {{page.name}} plugin forwards a copy of your {{site.base_gateway}} API traffic to [Akamai API Security](https://www.akamai.com/products/api-security) for behavioral ML analysis, security inspection, and threat detection.
It can also enforce security policies by blocking malicious actors based on rules configured in Akamai API Security.

## Install the {{page.name}} plugin

### Prerequisites

The {{page.name}} plugin requires the creation of an integration profile in API Security. For complete instructions, visit the [Akamai API Security docs site](https://docs.nonamesecurity.com/docs/kong-plugin).

### Create the integration profile

Configure the integration profile in the Akamai API Security UI and download the plugin package:

1. In the Akamai API Security UI, navigate to **Settings** > **Integrations** > **Traffic Sources**.
1. Select **Add Integration**, then select the Kong tile to create an integration profile.
1. Download the zip file and copy it to your {{site.base_gateway}} machine, then select **Next**.
1. Provide an alias for the integration.
1. Select **Finish** to save the integration.

### Choose your installation method

{% navtabs "install-akamai" %}
{% navtab "Docker" %}

Use this method when {{site.base_gateway}} runs as a container and you build your own image.

1. Place the `.rock` file in the same directory as your Dockerfile, then add the following lines to your Dockerfile and build the image:

   ```docker
   USER root

   COPY ./kong-plugin-nonamesecurity-<version>.all.rock kong-plugin-nonamesecurity-<version>.all.rock

   RUN luarocks install kong-plugin-nonamesecurity-<version>.all.rock

   USER kong
   ```

1. Run the container with `nonamesecurity` included in the `KONG_PLUGINS` list:

   ```bash
   docker run -e "KONG_PLUGINS=bundled,nonamesecurity" ...
   ```

{% endnavtab %}
{% navtab "Kubernetes" %}

Use this method when {{site.base_gateway}} is deployed on Kubernetes using the official Helm chart.

1. Unpack the plugin package and locate the `kong/plugins/nonamesecurity/` directory.

1. Bundle the directory into a ConfigMap:

   ```bash
   kubectl create configmap kong-plugin-nonamesecurity --from-file=nonamesecurity -n kong
   ```

1. Update your Helm `custom-values.yaml` file to reference the ConfigMap:

   ```yaml
   plugins:
     configMaps:
       - pluginName: nonamesecurity
         name: kong-plugin-nonamesecurity
   ```

1. Update your deployment using Helm:

   ```bash
   helm upgrade kong kong/kong -n kong -f custom-values.yaml
   ```

1. Verify that the plugin loaded:

   ```bash
   kubectl logs -n kong deploy/kong-proxy | grep nonamesecurity
   ```

   Check the list of enabled plugins:
   ```bash
   curl http://localhost:8001/plugins/enabled
   ```

If you aren't using Helm, add the following to the `spec.container.env` section of your Kong Deployment or DaemonSet instead:

```yaml
env:
  - name: KONG_PLUGINS
    value: "bundled,nonamesecurity"
```

{% endnavtab %}
{% navtab "Package or server install" %}

Use this method when {{site.base_gateway}} runs directly on a host, for example RHEL, Debian, or Ubuntu.

1. Copy the `.rock` file to the {{site.base_gateway}} host.

1. Install it with LuaRocks. Use `sudo` if required, and use the absolute path (typically `/usr/local/bin/luarocks`) if `luarocks` isn't in `$PATH`:

   ```bash
   luarocks install kong-plugin-nonamesecurity-<version>.all.rock
   ```

1. Confirm that the installed `nonamesecurity` folder has the same owner and permissions as your other {{site.base_gateway}} plugin folders. This is typically mode `777`, owned by the `kong:kong` user and group.

1. Enable the plugin using one of the following options:

   Update `kong.conf`:

   ```bash
   plugins = bundled,nonamesecurity
   ```

   Or set the environment variable and restart {{site.base_gateway}}:

   ```bash
   export KONG_PLUGINS="bundled,nonamesecurity"
   ```

   ```bash
   kong restart
   ```

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

{{site.konnect_short_name}} hybrid mode (self-managed data planes) is supported. {{site.konnect_short_name}} Serverless and Dedicated Cloud Gateways can't run custom plugins.

Upload the plugin schema so the control plane can validate and distribute {{page.name}} configuration.

1. Unpack the `.rock` file to get to `schema.lua`:

   ```bash
   luarocks unpack kong-plugin-nonamesecurity-<version>.all.rock
   ```

   This creates a `kong-plugin-nonamesecurity-<version>/nonamesecurity/schema.lua` file relative to your current directory.

1. Set your {{site.konnect_short_name}} credentials:

   ```bash
   export KONNECT_TOKEN="your-konnect-personal-access-token"
   export CONTROL_PLANE_ID="your-control-plane-id"
   ```

1. Upload the schema, setting your own control plane ID and {{site.konnect_short_name}} access token:

   ```bash
   curl -i -X POST \
     "https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugin-schemas" \
     --header "Authorization: Bearer $KONNECT_TOKEN" \
     --header "Content-Type: application/json" \
     --data "{\"lua_schema\": $(jq -Rs '.' kong-plugin-nonamesecurity-<version>/nonamesecurity/schema.lua)}"
   ```

1. Install the `.rock` file (or a custom image containing it) on every data plane node, the same way you would for a Docker or Kubernetes deployment, and make sure `nonamesecurity` is included in `KONG_PLUGINS` on each data plane.
Uploading a changed schema doesn't push it to data planes on its own. Update or create another entity afterward so data planes pull the new payload.

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

Once installed, attach {{page.name}} at the global, Service, or Route level.
See the [Enable Akamai API Security example](/plugins/akamai-api-security/examples/enable-akamai-plugin/).
