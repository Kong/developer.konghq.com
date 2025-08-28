---
title: deck file openapi2kong
description: Convert an OpenAPI specification to Kong Services and Routes.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/

related_resources:
  - text: Request Validator plugin
    url: /plugins/request-validator/
  - text: OAS Validation plugin
    url: /plugins/oas-validation/
  - text: OpenID Connect plugin
    url: /plugins/openid-connect/

tags:
  - openapi
  - declarative-config

faqs:
  - q: When running `deck file openapi2kong`, I get the error `infinite circular reference detected`. How do I resolve it?
    a: |
      The solution depends on your use case. In some situations, [circular references](https://pb33f.io/libopenapi/circular-references/) may be valid for a particular API spec design. 

      With decK, you have two options:
        * Resolve the circular references
        * {% new_in 1.51.0 %} Pass the `--ignore-circular-refs` flag to the command to ignore circular references and continue converting the file:
          
          ```sh
          deck file openapi2kong -s /tmp/openapi.yaml --ignore-circular-refs
          ```
        Use this option with caution.

---

The `openapi2kong` command converts an OpenAPI specification to Kong's declarative configuration format.

- A Service is created, pointing to the URLs in the `servers` block
- One Route per `operationId` is created
- If an `openIdConnect` `securityScheme` is present, an `openid-connect` plugin will be generated

## Convert an OpenAPI file to a Kong state file

Converting an OpenAPI file to a Kong declarative configuration can be done in a single command:

```bash
deck file openapi2kong --spec oas.yaml --output-file kong.yaml
```

## Best practices

The following sections list some best practices for conversion from OAS format into Kong declarative files.

### ID Generation

The `openapi2kong` command generates a declarative configuration file that contains an `id` for each entity. This ensures that even if the entity name (or any other identifying parameter) changes, it will update an entity in {{ site.base_gateway }} rather than deleting then recreating an entity.

If you have an existing {{ site.base_gateway }} instance, you can use the `--inso-compatible` flag to skip ID generation. In this instance, decK will match entities on a best effort basis using the `name` field.

If you have multiple teams using the same names and `operationId` values in their specifications, you can specify the `--uuid-base` flag to set a custom namespace when generating IDs.

To learn more about ID generation, see the [openapi2kong GitHub documentation](https://github.com/Kong/go-apiops/blob/main/docs/oas2kong-id-generation-deck.md#id-generation).

### Adding plugins

`openapi2kong` allows you to configure plugins directly in your OpenAPI specification by providing an `x-kong-plugin-PLUGIN-NAME` annotation at the root level to add it to the Service, at the path level to add it to all Routes on that path, or on an operation to add it to a specific Route.

_However_, we do not recommend using this functionality. Routing and policy enforcement are generally owned by different teams, and you do not want to publish a plugin configuration in an OpenAPI specification that is shared with customers.

We recommend using the [add-plugin](/deck/file/manipulation/plugins/) command after the `openapi2kong` command has been run.

If you really want to embed plugin configuration in your OpenAPI specification, here is an example extension that adds the `request-termination` plugin to a Route:

```yaml
x-kong-request-termination:
  status_code: 403
  message: So long and thanks for all the fish!
```

There are two exceptions to this recommendation:

- Configuring OpenID Connect scopes
- Dynamically generating request validator plugins for all endpoints

#### Configuring OpenID Connect scopes

[OpenID Connect](/plugins/openid-connect/) allows you to check for specific scopes when accessing a Route. App development teams know which scopes are required for the paths their application serves.

To define scopes on a per-path level, use the `x-kong-security-openid-connect` annotation at the same level as `operationId`.

```yaml
x-kong-security-openid-connect:
  config:
    scopes_required: ["scope1", "scope2"]
```

#### Dynamic request-validator plugin configuration

The Kong [Request Validator plugin](/plugins/request-validator/) can validate incoming requests against a user-provided JSON schema.

The plugin can be configured manually, but `openapi2kong` can use the provided OpenAPI specification to configure the Request Validator plugin for all Routes automatically. To enable this behavior, add the `x-kong-plugin-request-validator` at the root level to add it to all routes, at the path level to add it to all Routes on that path, or on an operation to add it to a specific Route.

Omitting the `body_schema` and `parameter_schema` configuration options tells `openapi2kong` to automatically inject the schema for the current endpoint when generating a {{ site.base_gateway }} declarative configuration file.

```yaml
x-kong-plugin-request-validator:
  config:
    verbose_response: true
```

## Custom x-kong extensions

The `openapi2kong` command supports the following custom `x-kong` extensions to customize the declarative configuration file generation:

<!--vale off-->
{% table %}
columns:
  - title: Annotation
    key: annotation
  - title: Description
    key: description
rows:
  - annotation: "`x-kong-tags`"
    description: |
      Specify the [tags](/gateway/tags/) to use for each {{site.base_gateway}} entity generated. 
      Tags can be overridden when doing the conversion. This can only be specified at the document level.
  - annotation: "`x-kong-service-defaults`"
    description: |
      The defaults for the [Services](/gateway/entities/service/) generated from the `servers` object in the OpenAPI spec. These defaults can also be added to the `path` and `operation` objects, which will generate a new Service entity.
  - annotation: "`x-kong-upstream-defaults`"
    description: |
      The defaults for [Upstreams](/gateway/entities/upstream/) generated from the `servers` object in the OpenAPI spec. These defaults can also be added to the `path` and `operation` objects, which will generate a new Service entity.
  - annotation: "`x-kong-Route-defaults`"
    description: 
      The defaults for the [Routes](/gateway/entities/route/) generated from `paths` in the OpenAPI spec.
  - annotation: "`x-kong-name`"
    description: |
      The name for the entire spec file. This is used for naming the Service and upstream objects in {{site.base_gateway}}.
      If not given, it will use the `info.title` field to name these objects, or a random UUID if the `info.title` field is missing.
      <br><br>
      Names are converted into valid identifiers. This directive can also be used on `path` and `operation` objects to name them.
      <br><br>
      Similarly to `operationId`, each `x-kong-name` must be unique within the spec file.
  - annotation: "`x-kong-plugin-KONG_PLUGIN_NAME`"
    description: >-
      Directive to add a plugin. The plugin name is derived from the extension name and is a generic mechanism that can add any type of plugin.
      This plugin is configured on a global level for the OpenAPI spec. As such, it is configured on the Service entity, and applies on all paths and operations in this spec.
      <br><br>
      The plugin name can also be specified on paths and operations to override the config for that specific subset of the spec. In that case,
      it is added to the generated Route entity. If new Service entities are generated from `path` or `operation` objects, the plugins are copied
      over accordingly (for example, by having `servers` objects, or upstream or Service defaults specified on those levels).
      <br><br>
      A Consumer can be referenced by setting the `consumer` field to the Consumer name or ID.
      <br><br>
      _**Note:** Since the plugin name is in the key, only one instance of each plugin can be added at each level._
  - annotation: "`securitySchemes.[...].x-kong-security-openid-connect`"
    description: |
      Specifies that the [OpenID Connect plugin](/plugins/openid-connect/) is to be used to implement this `security scheme object`. Any custom configuration can be added as usual for plugins.
  - annotation: "`components.x-kong`"
    description: |
      Reusable {{site.base_gateway}} configuration components. All `x-kong` references must be under this key.
      It accepts the following referenceable elements:
        * `x-kong-service-defaults`
        * `x-kong-upstream-defaults`
        * `x-kong-route-defaults`
        * `x-kong-plugin-[...] Plugin configurations`
        * `x-kong-security-[...] Plugin configurations`
{% endtable %}
<!--vale on-->

## Command usage

{% include_cached deck/help/file/openapi2kong.md %}
