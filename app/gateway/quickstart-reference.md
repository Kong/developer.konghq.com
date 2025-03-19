---
title: "{{site.base_gateway}} quickstart script reference"
content_type: reference
layout: reference

products:
  - gateway

tags:
  - ai-gateway

min_version:
  gateway: '3.4'

description: "Kong offers a quickstart script that launches a local instance of {{site.base_gateway}} for testing."

related_resources:
  - text: "{{site.base_gateway}}"
    url: /gateway/
  - text: Get started with {{site.base_gateway}}
    url: /how-to/get-started-with-gateway/
  - text: Kong AI Gateway
    url: /ai-gateway/
---

Kong offers a quickstart script that allows you to easily run a local instance of {{site.base_gateway}} for testing purposes.
You can view the 

To run this quickstart you need to:
* Start Docker
* Store your Kong license data in the `KONG_LICENSE_DATA` environment variable

{% capture base_cmd %}curl -Ls https://get.konghq.com/quickstart | bash -s --  \
          -e KONG_LICENSE_DATA{% endcapture %}

Once this is done, run this command to create the Docker containers for {{site.base_gateway}} and its database:
```sh
{{base_cmd}}
```

If needed, you can pass different flags and parameters to the script. For example:

{% table %}
columns:
  - title: Description
    key: desc
  - title: Command example
    key: cmd
rows:
  - desc: Get information about the command
    cmd: |
      ```sh
      curl -Ls https://get.konghq.com/quickstart | bash -s -- -h
      ```
  - desc: Run in DB-less mode
    cmd: |
      ```sh
      {{base_cmd}} \
          -D
      ```
  - desc: Enable Prometheus metrics
    cmd: |
      ```sh
      {{base_cmd}} \
          -m
      ```
  - desc: |
      [Enable RBAC](/gateway/entities/rbac/#enable-rbac)
    cmd: |
      ```sh
      {{base_cmd}} \
          -e KONG_ENFORCE_RBAC=on
      ```
  - desc: Add third-party credentials
    cmd: |
      ```sh
      {{base_cmd}} \
          -e AZURE_CLIENT_SECRET
      ```
{% endtable %}


## AI Gateway quickstart {% new_in 3.6 %}
Kong also provides an interactive AI quickstart script that launches a demo instance of {{site.base_gateway}} running [AI Proxy](/plugins/ai-proxy/):

```sh
curl -Ls https://get.konghq.com/ai | bash -s -- -e KONG_LICENSE_DATA
```

The script can either run a {{site.base_gateway}} instance in traditional mode or as a data plane instance for {{site.konnect_short_name}}. You will be prompted to input an API key to configure authentication with an AI provider. 
This key will not be exposed outside of the host machine.

The script creates a [Gateway Service](/gateway/entities/service/) with two [Routes](/gateway/entities/route/), and configures the AI Proxy plugin on those Routes based on the provider that you specify.

Check out the full script at [https://get.konghq.com/ai](https://get.konghq.com/ai) to see which entities 
it generates, and access all of your Routes and Services by visiting either [Gateway Manager in {{site.konnect_short_name}}](https://cloud.konghq.com/gateway-manager/) or 
[Kong Manager](/gateway/kong-manager/) at `https://localhost:8002` in any browser.

{:.info}
> **Note:**
> By default, local models are configured on the endpoint `http://host.docker.internal:11434`,
> which allows {{site.base_gateway}} running in Docker to connect to the host machine. 