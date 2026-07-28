---
title: "Using kongctl to manage {{site.ai_gateway}}"
content_type: reference
layout: reference

description: "Learn how to use kongctl to create and inspect {{site.ai_gateway}} resources in {{site.konnect_product_name}}."

breadcrumbs:
  - /ai-gateway/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.0'

tags:
  - declarative-config
  - cli

related_resources:
  - text: "Get started with {{site.ai_gateway}}"
    url: /ai-gateway/get-started/
  - text: "Declarative configuration with kongctl"
    url: /kongctl/declarative/
  - text: "kongctl and decK"
    url: /kongctl/kongctl-and-deck/
  - text: "{{site.ai_gateway}} v2 migration guide"
    url: /ai-gateway/v2-migration-guide/
  - text: "kongctl supported resources"
    url: /kongctl/supported-resources/
  - text: "Configuration of kongctl"
    url: /kongctl/config/
next_steps:
  - text: "Get started with {{site.ai_gateway}}"
    url: /ai-gateway/get-started/
---

kongctl is the CLI for managing [{{site.ai_gateway}} resources](/ai-gateway/entities/) in {{site.konnect_product_name}}.
It supports two modes of operation: declarative configuration for managing resources as code, and imperative commands for one-off operations and inspection.

{:.info}
> **Note**: 
> kongctl manages {{site.ai_gateway}} on {{site.konnect_product_name}}.
> decK manages {{site.base_gateway}} entities (Services, Routes, Plugins, and so on) on self-managed deployments.
> If you're coming from {{site.ai_gateway}} 1.x, which used decK and Gateway plugins, see the [v2 migration guide](/ai-gateway/v2-migration-guide/) for how to move to the kongctl-managed entity model.

{{site.ai_gateway}} resources are regional.
Make sure your active kongctl profile's `konnect.region` matches the region where your {{site.ai_gateway}} lives (`us`, `eu`, `au`, `me`, `in`, or `sg`).
See [Configuration of kongctl](/kongctl/config/) for how to set this.

## Declarative configuration

In declarative mode, you describe the desired state of your resources in declarative configuration files and kongctl calculates and applies the diff.
This is the recommended approach for most {{site.ai_gateway}} configuration because it lets you store configuration in source control and apply it safely at any time.

The {{site.ai_gateway}} [how-to guides](/how-to/?products=ai-gateway) use this approach.

### Workflow

Use the following workflow to manage {{site.ai_gateway}} resources declaratively:

* Write a configuration file describing the resources you want.
* Run `kongctl plan -f example.yaml` to preview what will change (optional but recommended).
* Run `kongctl apply -f example.yaml` to create or update resources.
* Run `kongctl sync -f example.yaml` when you want kongctl to also create, update, or delete resources. 
See the [kongctl sync reference](/kongctl/sync/) for more detail on sync behavior.

For example, this configuration file creates an {{site.ai_gateway}}:

```yaml
_defaults:
  kongctl:
    namespace: my-namespace

ai_gateways:
  - ref: my-ai-gateway
    name: my-ai-gateway
```

Save this as `ai-gateway.yaml`, then preview what will change:

```bash
kongctl diff --mode apply -f ai-gateway.yaml --pat "$KONNECT_TOKEN"
```

Then apply, confirming the changes if you approve:

```bash
kongctl apply -f ai-gateway.yaml --pat "$KONNECT_TOKEN"
```

For a step-by-step guide, see [Get started with {{site.ai_gateway}}](/ai-gateway/get-started/), which walks through creating an AI Provider and AI Model using `kongctl apply`.

For the full declarative configuration reference, see [Declarative configuration with kongctl](/kongctl/declarative/).

### Resource schemas

To look up field names and required fields for any resource type, use `kongctl explain`:

```bash
kongctl explain ai_gateway_model_providers
```

Use `kongctl scaffold` to generate starter YAML for a resource type:

```bash
kongctl scaffold ai_gateway_model_providers
```

See the [kongctl declarative resource reference](/kongctl/supported-resources/#ai-gateway) for all supported resource types.

### Adopting an existing {{site.ai_gateway}}

If you create an {{site.ai_gateway}} using declarative configuration, kongctl tracks it in the namespace automatically.

If an {{site.ai_gateway}} already exists in {{site.konnect_product_name}} (for example, one provisioned outside of kongctl), use [`kongctl adopt`](/kongctl/adopt/) to bring it into a namespace before managing it declaratively:

```sh
kongctl adopt ai-gateway "$AI_GATEWAY_ID" \
    --namespace my-namespace \
    --pat "$KONNECT_TOKEN"
```

`adopt` registers the existing {{site.ai_gateway}} with a kongctl namespace so it can be tracked.
Pre-existing resources need to be adopted before kongctl includes them in plan and sync operations.

After adopting, run `kongctl dump declarative` to export the current configuration as a YAML file you can use as the starting point for declarative management:

```bash
kongctl dump declarative \
  --default-namespace my-namespace \
  --resources ai_gateways,ai_gateway_models,ai_gateway_model_providers \
  --pat "$KONNECT_TOKEN" > ai-gateway.yaml
```

From here you can edit `ai-gateway.yaml`, commit it to source control, and manage the resource going forward with commands like `kongctl apply` or `kongctl sync`.

### Referencing external resources

When a resource already exists in {{site.konnect_product_name}} but isn't managed by your current configuration file, you can reference it without taking ownership.
kongctl provides two ways to do this: `_external` and `!lookup`.
* Use `_external` when multiple child resources in the same file share the same parent, so you only need to write the lookup once and reference it by `ref`.
* Use `!lookup` when you only need the parent's ID in a single field and want to keep the config concise.

`_external` declares the resource as a named block with a `ref` you can reuse multiple times in the same file:

```yaml
ai_gateways:
  - ref: my-ai-gateway
    _external:
      selector:
        matchFields:
          name: "my-ai-gateway"

ai_gateway_model_providers:
  - ref: openai-primary
    ai_gateway: my-ai-gateway
    name: openai-primary
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_API_KEY
```

`!lookup` is a concise inline tag that performs the same lookup directly in a field value:

```yaml
ai_gateway_model_providers:
  - ref: openai-primary
    ai_gateway: !lookup name:my-ai-gateway
    name: openai-primary
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_API_KEY
```

In both situations, kongctl resolves the external resource's ID at plan time and uses it to scope the child resources.
The external resource itself is not modified or deleted by `sync`.

### Commands reference

These are the commands you'll use most often in a declarative workflow:

{% include_cached /kongctl/commands-reference-table.md %}

## Imperative commands

For inspection and one-off operations, use [`kongctl get`](/kongctl/get/), [`kongctl create`](/kongctl/create/), and [`kongctl delete`](/kongctl/delete/) directly.
These commands don't require a configuration file and take effect immediately without going through a plan.

List all {{site.ai_gateway}} instances in your organization:

```sh
kongctl get ai-gateways
```

List resources scoped to a specific {{site.ai_gateway}}, for example:

```sh
kongctl get ai-gateway model-providers --gateway-name "my-ai-gateway"
kongctl get ai-gateway models --gateway-name "my-ai-gateway"
kongctl get ai-gateway policies --gateway-name "my-ai-gateway"
kongctl get ai-gateway consumers --gateway-name "my-ai-gateway"
kongctl get ai-gateway mcp-servers --gateway-name "my-ai-gateway"
```

Pass `--help` to any subcommand to see available flags and filtering options.
For example, passing it to `kongctl get ai-gateway` will give you a list of all {{site.ai_gateway}} resources kongctl can manage:

```sh
kongctl get ai-gateway --help
```
