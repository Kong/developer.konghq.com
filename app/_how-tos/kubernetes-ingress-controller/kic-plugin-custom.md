---
title: Deploy custom plugins
description: "Install custom plugins in {{ site.base_gateway }} without using a custom image"
content_type: how_to
permalink: /kubernetes-ingress-controller/custom-plugins/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: How To

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I install custom lua plugins using {{ site.kic_product_name }}?
  a: Store the plugin contents in a `ConfigMap` and mount the `ConfigMap` as a volume on your Pods.

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service
---

## Custom plugins

Custom Lua plugins can be stored in a Kubernetes ConfigMap or Secret and mounted in your {{ site.base_gateway }} Pod.

The examples in this guide use a `ConfigMap`, but you can replace any references to `configmap` with `secret` to use a `Secret` instead.

{:.info}
> If you would like to install a plugin which is available as a rock from Luarocks, then you need to download it, unzip it and create a ConfigMap from all the Lua files of the plugin.

{% include_cached plugins/custom-plugin-example.md %}


## Create a ConfigMap

Create a `ConfigMap` from your directory that will be mounted to your {{ site.base_gateway }} Pod:

```bash
kubectl create configmap kong-plugin-myheader --from-file=myheader -n kong
```

If your custom plugin includes new entities, you need to create a `daos.lua` file in your directory and a `migration` sub-directory containing the scripts to create any database tables and migrate data between different versions (if your entities' schemas changed between different versions). In this case, the directory should like this:

```bash
  myheader
  ├── daos.lua
  ├── handler.lua
  ├── migrations
  │   ├── 000_base_my_header.lua
  │   ├── 001_100_to_110.lua
  │   └── init.lua
  └── schema.lua

  1 directories, 6 files
```
{:.no-copy-code}

As a `ConfigMap` does not support nested directories, you need to create another `ConfigMap` containing the `migrations` directory:

```bash
kubectl create configmap kong-plugin-myheader-migrations --from-file=myheader/migrations -n kong
```

## Deploy your custom plugin

Kong provides a way to deploy custom plugins using both {{ site.operator_product_name }} and the {{ site.kic_product_name }} Helm chart. This guide shows how to use the Helm chart, but we recommend using {{ site.operator_product_name }} if possible. See [Kong custom plugin distribution with KongPluginInstallation](/operator/dataplanes/how-to/deploy-custom-plugins/) for more information.

The {{ site.kic_product_name }} Helm chart automatically configures all the environment variables required based on the plugins you inject.

1. Update your `values.yaml` file with the following contents. Ensure that you add in other configuration values you might need for your installation to be successful.

    ```yaml
    gateway:
      plugins:
        configMaps:
          - name: kong-plugin-myheader
            pluginName: myheader
    ```

    If you need to include the migration scripts to the plugin, configure `userDefinedVolumes` and `userDefinedVolumeMounts` in `values.yaml` to mount the migration scripts to the {{site.base_gateway}} pod:

    ```yaml
    gateway:
      plugins:
        configMaps:
          - name: kong-plugin-myheader
            pluginName: myheader
      deployment:
        userDefinedVolumes:
          - name: "kong-plugin-myheader-migrations"
            configMap:
              name: "kong-plugin-myheader-migrations"
        userDefinedVolumeMounts:
          - name: "kong-plugin-myheader-migrations"
            mountPath: "/opt/kong/plugins/myheader/migrations" # Should be the path /opt/kong/plugins/<plugin-name>/migrations
    ```

1. Upgrade {{site.kic_product_name}} with the new values

    ```bash
    helm upgrade --install kong kong/ingress -n kong --create-namespace --values values.yaml
    ```

{% konnect %}
title: Register the plugin schema in Konnect
step: true
content: |
  To see your custom plugin in {{site.konnect_product_name}}, you need to register the schema with your control plane: 

  ```sh
  curl -X POST \
    https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugin-schemas \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $KONNECT_TOKEN" \
    --data "{\"lua_schema\": $(jq -Rs . './myheader/schema.lua')}"
  ```
{% endkonnect %}

## Using custom plugins

{:.warning}
> If you get a "plugin failed schema validation" error, wait until your {{ site.base_gateway }} Pods have cycled before trying to create a `KongPlugin` instance

After you have set up {{ site.base_gateway }} with the custom plugin installed, you can use it like any other plugin by adding the `konghq.com/plugins` annotation. 

1. Create a KongPlugin custom resource:

{% entity_example %}
type: plugin
indent: 4
data:
  name: my-custom-plugin
  plugin: myheader
  config:
    header_value: "my first plugin"

  service: echo
{% endentity_example %}

1. Create a Route to the `echo` service to test your custom plugin: 

{% capture httproute %}
<!--vale off-->
{% httproute %}
name: echo
matches:
  - path: /echo
    service: echo
    port: 1027
skip_host: true
{% endhttproute %}
<!--vale on-->
{% endcapture %}

{{httproute | indent: 3}}

## Validate your configuration

Once the resource has been reconciled, you'll be able to call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` service.

The `-i` flag returns response headers from the server, and you will see `myheader: my first plugin` in the output:

{% validation request-check %}
url: /echo
status_code: 200
display_headers: true
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
