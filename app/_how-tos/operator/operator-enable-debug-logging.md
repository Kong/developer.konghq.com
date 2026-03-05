---
title: Enable debug logging
description: "Enable debug logging for {{ site.operator_product_name }} to troubleshoot issues."
content_type: how_to

permalink: /operator/dataplanes/how-to/enable-debug-logging/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - konnect
  - on-prem

prereqs:
  skip_product: true

tldr:
  q: How do I enable debug logging for {{ site.operator_product_name }}?
  a: Configure the `zap-log-level` and `zap-devel` environment variables via Helm values.

related_resources:
  - text: "Configuration Options"
    url: /operator/reference/configuration-options/

faqs:
  - q: How can I disable debug logging?
    a: |
      To return to normal logging levels, remove the debug configuration and upgrade:

      ```bash
      helm upgrade kong-operator kong/kong-operator \
        -n kong-system \
        --reset-values
      ```
  - q: Can I used arguments instead of environment variables to enable debug logging?
    a: |
      Yes, you can configure logging using flags in your `values.yaml`:

      ```yaml
      args:
        - --zap-log-level=debug
        - --zap-devel=true
        - --zap-time-encoding=iso8601
      ```
      
      The `env` and `args` sections are mutually exclusive. When both are provided, `args` takes precedence.
---

## Enable debug logging 

When installing or upgrading {{ site.operator_product_name }} with Helm, you can enable debug logging by adding the following to your `values.yaml`:

```sh
cat <<EOF > values.yaml
env:
  zap_log_level: debug
  zap_devel: "true"
  zap_time_encoding: iso8601
EOF
```

For more details about these options, see [{{ site.operator_product_name }} configuration options](/operator/reference/configuration-options/#flags).

## Install {{ site.operator_product_name }}

Run the following command to install {{ site.operator_product_name }} using the `values.yaml` file we created:

```bash
helm upgrade --install kong-operator kong/kong-operator -n kong-system \
  --create-namespace \
  --set image.tag={{ site.data.operator_latest.release }} \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  -f values.yaml
```
{:data-deployment-topology='konnect'}

```bash
helm upgrade --install kong-operator kong/kong-operator -n kong-system \
  --create-namespace \
  --set image.tag={{ site.data.operator_latest.release }} \
  -f values.yaml
```
{:data-deployment-topology='on-prem'}

## Validate

Use the following command to display the {{ site.operator_product_name }} logs:

```bash
kubectl logs -n kong-system deployment/kong-operator-kong-operator-controller-manager -f
```

You should see logs with the `DEBUG` level.

{:.info}
> Development mode (`--zap-devel=true`) uses a console encoder with colored, human-readable output. Production mode uses JSON encoding suitable for log aggregation systems.