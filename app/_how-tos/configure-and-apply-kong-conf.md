---
title: Configure and apply {{site.base_gateway}} configuration
content_type: how_to

related_resources:
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/
  - text: "{{site.base_gateway}} CLI"
    url: /gateway/cli/
  - text: "Managing {{site.base_gateway}} configuration"
    url: /gateway/manage-kong-conf/

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
  - kong-cli

tags:
    - configuration
    - "kong.conf"

tldr:
    q: How do I edit and apply my Kong configuration?
    a: |
      Use the `kong.conf` file to manage {{site.base_gateway}} instances. 

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
  gateway: '3.4'
---

## 1. Configure {{site.base_gateway}}

To configure {{site.base_gateway}}, make a copy of the default configuration file: 

```bash
cp /etc/kong/kong.conf.default /etc/kong/kong.conf
```

The file contains {{site.base_gateway}} configuration properties and documentation. 
{{site.base_gateway}} will use the default settings for any value in `kong.conf` that is commented out.

For example, let's edit the `log_level`. In `kong.conf`, uncomment the `log_level` property and modify the value:

```bash
log_level = warn
```

## 2. Load and apply configuration

To load the configuration file, we'll use the [Kong CLI](/gateway/cli/).
{{site.base_gateway}} reads this file when using `kong start` or `kong prepare`.

1. Run `kong prepare` to prepare the Kong prefix folder with all of its subfolders and files, including `kong.conf`.
2. Run either `kong reload` or `kong restart` to reboot the {{site.base_gateway}} instance and apply configuration.

## 3. Verify configuration

To verify that your configuration is usable, use the `kong check` command. 
The `kong check` command evaluates the parameters you have
currently set, and will output an error if your settings are invalid. 

For example:

```bash
kong check /etc/kong/kong.conf
```
If your configuration is valid, you will see the following response:

```bash
configuration at /etc/kong/kong.conf is valid
```
{:.no-copy-code}
