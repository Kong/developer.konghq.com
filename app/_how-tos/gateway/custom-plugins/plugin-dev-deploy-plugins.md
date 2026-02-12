---
title: Deploy a custom plugin with Docker
description: Deploy your custom plugin to {{site.base_gateway}}.
  
content_type: how_to

permalink: /custom-plugins/get-started/deploy-plugins/
breadcrumbs:
  - /custom-plugins/

series:
  id: plugin-dev-get-started
  position: 5

tldr:
  q: How can I deploy my custom plugin to {{site.base_gateway}}?
  a: Create a Dockerfile for your plugin, then build the image and run {{site.base_gateway}} with the custom image.

products:
  - gateway

tools:
  - admin-api

works_on:
  - on-prem

tags:
  - custom-plugins
  - pdk

prereqs:
  skip_product: true

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Plugins
    url: /gateway/entities/plugins/

automated_tests: false
---

## Create a Dockerfile

In this example, we'll use a Dockerfile to deploy our plugin, but there are other [deployment options](/custom-plugins/deployment-options/).

1. Create a file named `Dockerfile` at the root of the project:
   ```sh
   touch Dockerfile
   ```

1. Add the following content to the file:
   ```dockerfile
   FROM kong/kong-gateway:latest

   # Ensure any patching steps are executed as root user
   USER root

   # Add custom plugin to the image
   COPY ./kong/plugins/my-plugin /usr/local/share/lua/5.1/kong/plugins/my-plugin
   ENV KONG_PLUGINS=bundled,my-plugin

   # Ensure kong user is selected for image execution
   USER kong

   # Run kong
   ENTRYPOINT ["/entrypoint.sh"]
   EXPOSE 8000 8443 8001 8444
   STOPSIGNAL SIGQUIT
   HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
   CMD ["kong", "docker-start"]
   ```

## Build Docker image

Use the following command to build the Docker image:
```sh
docker build -t kong-gateway_my-plugin:latest-0.0.1 .
```

When building a Docker image we suggest tagging the image to include information about the {{site.base_gateway}} version and a version for the plugin.

## Run the custom image

You can now use the {{site.base_gateway}} quickstart script to run the
custom image and further test the plugin. 

The quickstart script supports
flags that allow you to override the Docker 
repository (`-r`), image (`-i`) and tag (`-t`).

Use the following command to run the quickstart with the custom image:
```sh
curl -Ls https://get.konghq.com/quickstart | \
  bash -s -- -r "" -i kong-gateway_my-plugin -t latest-0.0.1
```

## Test the deployed custom plugin

Once the {{site.base_gateway}} is running with the custom image, you 
can manually test the plugin and validate the behavior.

1. Add a test [Gateway Service](/api/gateway/admin-ee/#/operations/create-service):
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /services
status_code: 201
method: POST
body:
    name: example_service
    url: https://httpbin.konghq.com
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->

1. [Enable the plugin](/api/gateway/admin-ee/#/operations/create-plugin-with-service), this time with the configuration value:
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /services/example_service/plugins
status_code: 201
method: POST
body:
    name: my-plugin
    config:
      response_header_name: X-CustomHeaderName
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->

1. [Add a Route](/api/gateway/admin-ee/#/operations/create-route-with-service):
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /services/example_service/routes
status_code: 201
method: POST
body:
    name: example_route
    paths:
      - /mock
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->

1. Send a request to the Route:
<!-- vale off -->
{% capture request %}
{% validation request-check %}
url: '/mock/anything'
status_code: 200
display_headers: true
{% endvalidation %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on --> 
You should see the following response header:
```sh
X-CustomHeaderName: http://httpbin.konghq.com/anything
```
{:.no-copy-code}