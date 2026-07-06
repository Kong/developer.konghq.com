---
title: How to log the pod name of the {{site.base_gateway}} node that processed a request
content_type: support
description: Add the data plane pod name to {{site.base_gateway}} logging plugin output by exposing the container HOSTNAME variable through the config.custom_fields_by_lua property.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I add the data plane pod name to the log produced by a {{site.base_gateway}} logging plugin to identify which {{site.base_gateway}} pod processed the request?
  a: |
    In a Kubernetes environment, the container exposes a `HOSTNAME` variable set to the pod the
    container runs on. Using the environment variable Vault secret management backend, add this
    variable to the log plugin output by adding a new field to the plugin's
    `config.custom_fields_by_lua` property.
related_resources:
  - text: Logging plugins
    url: /plugins/?category=logging
  - text: Environment variable Vault
    url: /gateway/entities/vault/#vault-provider-specific-configuration-parameters
---


## Steps

In a Kubernetes environment, a container has a `HOSTNAME` variable set to the name of the pod it runs on.
Using the environment variable Vault secret management backend, you can expose this variable in log plugin output by adding a field to the plugin's `config.custom_fields_by_lua` property.

The following examples use the File Log plugin.

{% navtabs "config-method" %}
{% navtab "Admin API" %}

```bash
curl -X POST http://localhost:8001/WORKSPACE/plugins \
  -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "file-log",
    "config": {
      "custom_fields_by_lua": {
        "x-pod-name": "return kong.vault.get(\"{vault://env/hostname}\")"
      },
      "path": "/tmp/file.log"
    }
  }'
```

{% endnavtab %}
{% navtab "Declarative config" %}

```yaml
plugins:
- name: file-log
  enabled: true
  config:
    custom_fields_by_lua:
      x-pod-name: return kong.vault.get("{vault://env/hostname}")
    path: /tmp/file.log
    reopen: false
```

{% endnavtab %}
{% endnavtabs %}
