---
title: Custom plugin deployment options
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn about the different ways to deploy a custom plugin.

tags:
  - custom-plugins

min_version:
  gateway: '3.4'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: Installation and distribution
    url: /custom-plugins/installation-and-distribution/
  - text: Deploy a custom plugin with Docker
    url: /custom-plugins/get-started/deploy-plugins/
---

## Docker image

A very popular choice for running {{site.base_gateway}} is using container runtime systems. Kong builds and verifies Docker images for use in your deployments and provides detailed instructions on Docker deployments.

You can deploy your custom plugins by building a Docker image that adds your custom plugin code and sets the necessary environment directly in the image. This solution requires more steps in the build stage of your deployment pipeline, but simplifies the data plane deployment as configuration and custom code is shipped directly in the data plane image.

For more details, see the example in the [getting started guide](/custom-plugins/get-started/deploy-plugins/).

## Kubernetes

Many users choose to run {{site.base_gateway}} on Kubernetes. {{site.base_gateway}} can 
be deployed on Kubernetes directly or by using [{{site.kic_product_name}}](/kubernetes-ingress-controller/latest/).
In either case, deploying custom plugins on Kubernetes is achieved by adding the custom plugin 
code to the cluster in a ConfigMap or Secret and mounting it into the {{site.base_gateway}} proxy pods. Additionally,
the pods must be configured to load the custom plugin code from the mounted volume.

Kong provides a [Helm chart](/kubernetes-ingress-controller/custom-plugins/) which simplifies this process by configuring the necessary environment for the proxy pods
based on the plugin you configure. For a [non-Helm deployment](), you will need to modify the environment directly.
<!-- @TODO: add link to non-helm deployment docs, page does not exist yet, see https://kongdeveloper.netlify.app/kubernetes-ingress-controller/custom-plugins/#deploy-your-custom-plugin -->

## Package path

When running {{site.base_gateway}} in bare metal or virtual machine environments, overriding the 
location that the Lua VM looks for packages to include is a common strategy for deploying a custom plugin.
Following the same file structure as shown above, you can distribute the source files on the 
host machines and modify the `lua_package_path` configuration value to point to this path.
This configuration can also be modified using the `KONG_LUA_PACKAGE_PATH` environment variable. 

See the custom plugin [installation documentation](/custom-plugins/installation-and-distribution/) 
for more details on this option. 

{:.info}
> **Note**: In addition to bare metal or virtual machine environments, this strategy can work for volume mounts on containerized systems. 

## LuaRocks package

LuaRocks is a package manager for Lua modules. It allows you to create and install Lua modules
as self-contained packages called _rocks_. In order to create a _rock_ package you author
a _rockspec_ file that specifies various information about your package. Using the `luarocks` tooling,
you build an archive from the rockspec file and deliver and extract it to your data planes. 

See the [Packaging sources](/custom-plugins/installation-and-distribution/#packaging-sources) 
section of the custom plugin installation page for details on this distribution option.

## {{site.konnect_product_name}}

[{{site.konnect_product_name}}](/konnect-platform/) is Kong's unified API platform as a service. {{site.konnect_short_name}}
supports custom plugins with some limitations. With an on-premise deployment, users manage {{site.base_gateway}}
data planes as well as the control plane and, optionally, the backing database. In {{site.konnect_product_name}},
the control plane and database are fully managed for you which limits support for custom data entities and 
Admin API extensions in your plugin. 

<!-- TODO add link when this page is migrated: https://docs.konghq.com/konnect/gateway-manager/plugins/add-custom-plugin/ >