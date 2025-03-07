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
  - text: All decK documentation
    url: /index/deck/
---

The `openapi2kong` command converts an OpenAPI specification to Kong's declarative configuration format.

- A Service is created, pointing to the URLs in the `servers` block
- One Route per `operationId` is created
- If an `openIdConnect` `securityScheme` is present, an `openid-connect` Plugin will be generated

## Get started

Converting an OpenAPI file to a Kong declarative configuration can be done in a single command:

```bash
deck file openapi2kong --spec oas.yaml --output-file kong.yaml
```

## Best practices

### ID Generation

The `openapi2kong` command will generate a declarative configuration file that contains an `id` for each entity. This ensures that even if the entity name (or any other identifying parameter) changes, it will update an entity in {{ site.base_gateway }} rather than deleting then recreating an entity.

If you have an existing {{ site.base_gateway }} instance, you can use the `--inso-compatible` flag to skip ID generation. In this instance, decK will match entities on a best effort basis using the `name` field.

If you have multiple teams using the same names and `operationId` values in their specifications, you can specify the `--uuid-base` flag to set a custom namespace when generating IDs.

To learn more about ID generation, see the [openapi2kong GitHub documentation](https://github.com/Kong/go-apiops/blob/main/docs/oas2kong-id-generation-deck.md#id-generation).

### Adding Plugins

`openapi2kong` allows you to configure Plugins directly in your OpenAPI specification by providing an `x-kong-plugin-PLUGIN-NAME` annotation at the root level to add it to the Service, at the path level to add it to all Routes on that path, or on an operation to add it to a specific Route.

_However_, we do not recommend using this functionality. Routing and policy enforcement are generally owned by different teams, and you do not want to publish a Plugin configuration in an OpenAPI specification that is shared with customers.

We recommend using the [add-plugin](/deck/file/manipulation/plugins/) command after the `openapi2kong` command has been run.

If you really want to embed Plugin configuration in your OpenAPI specification, here is an example extension that adds the `request-termination` Plugin to a Route:

```yaml
x-kong-request-termination:
  status_code: 403
  message: So long and thanks for all the fish!
```

There are two exceptions to this recommendation:

- Configuring OpenID Connect scopes
- Dynamically generating request validator Plugins for all endpoints

#### Configuring OpenID Connect scopes

OpenID Connect allows you to check for specific scopes when accessing a Route. App development teams know which scopes are required for the paths their application serves.

To define scopes on a per-path level, use the `x-kong-security-openid-connect` annotation at the same level as `operationId`.

```yaml
x-kong-security-openid-connect:
  config:
    scopes_required: ["scope1", "scope2"]
```

#### Dynamic request-validator Plugin configuration

The Kong `request-validator` Plugin can validate incoming requests against a user-provided JSON schema.

The Plugin can be configured manually, but `openapi2kong` can use the provided OpenAPI specification to configure the `request-validator` Plugin for all Routes automatically. To enable this behavior, add the `x-kong-plugin-request-validator` at the root level to add it to all routes, at the path level to add it to all Routes on that path, or on an operation to add it to a specific Route.

Omitting the `body_schema` and `parameter_schema` configuration options tells `openapi2kong` to automatically inject the schema for the current endpoint when generating a {{ site.base_gateway }} declarative configuration file.

```yaml
x-kong-plugin-request-validator:
  config:
    verbose_response: true
```

## Custom x-kong extensions

The `openapi2kong` command supports the following custom `x-kong` extensions to customize the declarative configuration file generation:

| Annotation                                             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `x-kong-tags`                                          | Specify the [tags](/api/gateway/admin-ee/#/Tags) to use for each {{site.base_gateway}} entity generated. Tags can be overridden when doing the conversion. This can only be specified at the document level.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `x-kong-service-defaults`                              | The defaults for the [Services](/api/gateway/admin-ee/#/Services) generated from the `servers` object in the OpenAPI spec. These defaults can also be added to the `path` and `operation` objects, which will generate a new Service entity.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `x-kong-upstream-defaults`                             | The defaults for [upstreams](/api/gateway/admin-ee/#/Upstreams) generated from the `servers` object in the OpenAPI spec. These defaults can also be added to the `path` and `operation` objects, which will generate a new Service entity.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `x-kong-Route-defaults`                                | The defaults for the [routes](/api/gateway/admin-ee/#/Routes) generated from `paths` in the OpenAPI spec.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `x-kong-name`                                          | The name for the entire spec file. This is used for naming the Service and upstream objects in {{site.base_gateway}}. If not given, it will use the `info.title` field to name these objects, or a random UUID if the `info.title` field is missing. Names are converted into valid identifiers. This directive can also be used on `path` and `operation` objects to name them. Similarly to `operationId`, each `x-kong-name` must be unique within the spec file.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `x-kong-plugin-<kong-plugin-name>`                     | Directive to add a Plugin. The Plugin name is derived from the extension name and is a generic mechanism that can add any type of Plugin. This Plugin is configured on a global level for the OpenAPI spec. As such, it is configured on the Service entity, and applies on all paths and operations in this spec. <br><br> The Plugin name can also be specified on paths and operations to override the config for that specific subset of the spec. In that case, it is added to the generated Route entity. If new Service entities are generated from `path` or `operation` objects, the Plugins are copied over accordingly (for example, by having `servers` objects, or upstream or Service defaults specified on those levels). <br><br> A Consumer can be referenced by setting the `consumer` field to the Consumer name or ID. <br><br>**Note:** Since the Plugin name is in the key, only one instance of each Plugin can be added at each level. |
| `securitySchemes.[...].x-kong-security-openid-connect` | Specifies that the [OpenID Connect Plugin](/plugins/openid-connect) is to be used to implement this `security scheme object`. Any custom configuration can be added as usual for Plugins.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `components.x-kong`                                    | Reusable {{site.base_gateway}} configuration components. All `x-kong` references must be under this key. It accepts the following referenceable elements: <br> &#8226; `x-kong-service-defaults`<br> &#8226; `x-kong-upstream-defaults` <br> &#8226; `x-kong-route-defaults` <br> &#8226; `x-kong-plugin-[...] Plugin configurations` <br> &#8226; `x-kong-security-[...] Plugin configurations`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |

For more information and examples of these annotations, see the commented [example openapi2kong OAS](https://github.com/Kong/go-apiops/blob/main/docs/learnservice_oas.yaml).
