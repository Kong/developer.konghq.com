---
title: Custom plugins in {{site.konnect_short_name}} hybrid mode
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn how to deploy a custom plugin in {{site.konnect_short_name}}.

tags:
  - custom-plugins
  - gateway-manager

min_version:
  gateway: '3.4'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/

faqs:
  - q: What does a non-breaking change to a plugin schema look like?
    a: |
      A non-breaking change to a plugin schema fits the following criteria:
        * No default values
        * Parameter isn't marked as required

      Adding a non-breaking schema change won't disrupt Data Plane payload validation. 
      This means that even if new plugins are added or existing ones are updated, the Data Plane will 
      stay in sync because null fields are gracefully handled and ignored.

      Here's an example of a non-breaking change to a schema. This snippet adds a non-required 
      `new_ttl` configuration parameter without a default value, and a response 
      header that references an existing `typedef`:

      ```lua
      { 
          new_ttl = {
              type = "integer",
              gt = 0,
          }
      },
      { 
          new_response_header = typedefs.header_name
      },
      ```

      Similar to adding fields, when not-required fields are deleted, it doesn't break the Data Plane - even when a plugin is created or updated.
  - q: How does the {{site.konnect_short_name}} platform read plugin configuration?
    a: |
      When a schema file is updated in {{site.konnect_short_name}}, the {{site.konnect_short_name}} 
      platform doesn't trigger payload reconciliation automatically.

      This means that if you **don't** make any configuration changes in the Control Plane, such as adding, 
      modifying, or deleting a {{site.base_gateway}} entity, the Data Plane nodes won't receive a
      payload update, and won't use the updated schema.

      When pushing changes to the Control Plane, the payload reconciliation only affects 
      Data Plane nodes if an instance of the plugin that uses the updated schema has its 
      configuration changed.

      Since plugin configurations are stored as JSON blobs, a schema change alone doesn't impact the 
      plugin configuration. However, if an instance of this plugin is also updated, the new schema affects how 
      any new plugin configuration is represented.

      In summary:
      * Uploading a custom plugin schema adds a new configurable object to the {{site.konnect_short_name}} Plugin Hub, 
      both as a tile in the UI, and an API endpoint.
      * Modifying the schema itself does not trigger payload updates to Data Plane nodes.
      * The new tile or endpoint added by the schema lets you create plugin configurations.
      If you create a plugin configuration in this way, it triggers a payload reconciliation with the Data Plane nodes.

---

You can add custom plugins to API Gateway in {{site.konnect_short_name}} by uploading a Lua schema file to a Control Plane.

Using that schema, Gateway creates a plugin configuration object in {{site.konnect_short_name}},
making the plugin available for configuration alongside all the Kong bundled plugins. 
This means that {{site.konnect_short_name}} only sees a custom plugin's configuration options, and doesn't see any other plugin code.

{:.info}
> **Note**: For adding custom plugins to a Dedicated Cloud Gateway, see 
[Custom plugins in Dedicated Cloud Gateways](/dedicated-cloud-gateways/reference/#custom-plugins).

## Requirements

To run in {{site.konnect_short_name}}, a custom plugin must meet the following requirements:

**General requirements:**
* Each custom plugin must have a unique name.
* All plugin files must also be deployed to **each** {{site.base_gateway}} Data Plane node.

**File structure requirements:**
* The plugin must not contain an `api.lua` file, as Admin API extensions are not supported. 
* The plugin must not contain the `dao.lua` or `migrations.lua` files, as custom data entities are not supported.

**Code and language requirements:** 
* The schema for your custom plugin must be written in Lua, even if the custom plugin is written in [another supported language](/custom-plugins/#plugin-development-kits-pdks).
  If you have a custom plugin written in a language other than Lua, convert the schema into a `schema.lua` file before uploading it to {{site.konnect_short_name}}. 
* Custom validation functions must be written in Lua and be self-contained within the `schema.lua` file.
* The `schema.lua` file must not contain any `require()` statements.
* Plugins that require third-party libraries must reference them in the `handler.lua` file.

{:.warning}
> **Caution**: Carefully test the operation of any custom plugins before using them in production. 
Kong is not responsible for the operation or support of any custom plugins, 
including any performance impacts on your {{site.konnect_short_name}} or {{site.base_gateway}} deployments. 

## Deploying a custom plugin

To deploy a custom plugin in Hybrid mode, you need to separately deploy the plugin on the Control Plane and the Data Plane nodes.

### Add a custom plugin to a Control Plane

{{site.konnect_short_name}} only requires the custom plugin's `schema.lua` file. 
Using that file, it creates a plugin entry in the plugin catalog for your Control Plane.

Upload the `schema.lua` file for your plugin using the [`/plugin-schemas`](/api/konnect/control-planes-config/#/operations/create-plugin-schemas) endpoint:

```sh
curl -i -X POST \
  https://us.api.konghq.com/v2/control-planes/CONTROL_PLANE_ID/core-entities/plugin-schemas \
  --header 'Content-Type: application/json' \
  --data "{\"lua_schema\": your escaped Lua schema}"
```

You can also use [jq](https://jqlang.org/) to pass your schema directly from the file instead of manually escaping it:
```sh
--data "{\"lua_schema\": $(jq -Rs . './schema.lua')}"
```

Check that your schema was uploaded using the following request:

```sh
curl -i -X GET \
  https://us.api.konghq.com/v2/control-planes/CONTROL_PLANE_ID/core-entities/plugin-schemas/your-plugin
```

If it's successful, the request returns an `HTTP 200` response with the schema for your plugin as a JSON object.

### Upload files to Data Plane nodes

After uploading a schema to {{site.konnect_short_name}}, upload the `schema.lua` and `handler.lua` for your plugin to **each** {{site.base_gateway}} Data Plane node.

Follow the {{site.base_gateway}} [plugin deployment and installation instructions](/custom-plugins/installation-and-distribution/#install-the-plugin) 
to get your plugin set up on each node.

## Updating a custom plugin in {{site.konnect_short_name}} hybrid mode

The workflow for updating an in-use custom plugin depends on whether you need to update the schema:

* **No change to plugin schema:** Editing a custom plugin's logic **without** altering its schema won't 
cause the Control Plane to go out of sync with its Data Planes. 

  In this situation, you only need to make sure that each Data Plane node has the correct logic. 
  The schema on the Control Plane doesn't need to be updated.

* **Changes to plugin schema:** If there are changes required in the plugin schema, 
you must update both the schema in {{site.konnect_short_name}} and the plugin code itself on each Data Plane node. 
In this case, see the [custom plugin update paths](#custom-plugin-update-path) for possible scenarios and recommended paths.

* **Deleting a plugin and its schema**: If you need to completely remove the plugin from your
Control Plane, you must remove all existing plugin configurations of this entity, then remove 
the schema from the Control Plane and all plugin files from the Data Plane nodes.

There is no built-in versioning for custom plugins. 
If you need to version a schema (that is, maintain two or more similar copies of a custom plugin), 
upload it as a new custom plugin and add a version identifier to the name.
For example, if your original plugin is named `delay`, you can name the new version `delay-v2`.

### Custom plugin update paths

When you need to make plugin changes, we recommend updating the schema in {{site.konnect_short_name}} first, and then on the Data Plane nodes.

This is especially important making a [breaking change to the schema](#what-does-a-non-breaking-change-to-a-plugin-schema-look-like), 
as the change will affect each Data Plane node as soon as the node receives its first payload. 
This will happen even if there are no changes in the Control Plane for existing or new plugins using the updated schema. 

See the following table for a comparison of possible changes and upgrade paths, in the case of 
a configuration parameter change in a custom plugin's schema:

<!--vale off-->
{% table %}
columns:
  - title: Scenario
    key: scenario
  - title: Change to required default
    key: req_def
  - title: Change to required non-default
    key: req_non_def
  - title: Change to optional default
    key: opt_def
  - title: Change to optional non-default
    key: opt_non_def
rows:
  - scenario: Configuration parameter added to schema
    req_def: Short
    req_non_def: Long
    opt_def: Short
    opt_non_def: Short
  - scenario: Configuration parameter removed from schema
    req_def: Long
    req_non_def: "CP/DP sync required"
    opt_def: Long
    opt_non_def: Long
  - scenario: Configuration parameter's datatype changed
    req_def: "CP/DP sync required"
    req_non_def: "CP/DP sync required"
    opt_def: "CP/DP sync required"
    opt_non_def: "CP/DP sync required"
{% endtable %}
<!--vale on-->

Based on your specific use case, you have to take one of the following paths:

{% navtabs "paths" %}
{% navtab "Short" %}

1. Start a migration/maintenance window.
1. Update the plugin schema in {{site.konnect_short_name}}.  
1. Update the plugin schema on each Data Plane node.
1. Stop the migration/maintenance window.

{% endnavtab %}
{% navtab "Long" %}

1. Start a migration/maintenance window.
1. Update the plugin schema in {{site.konnect_short_name}}.  
1. Update the configuration for existing plugin instances.
1. Update the plugin schema on each Data Plane node.
1. Stop the migration/maintenance window.

{% endnavtab %}
{% navtab "CP/DP sync required" %}

1. Start a migration/maintenance window.
1. Update the plugin schema in {{site.konnect_short_name}}.  
1. (Optional) Update the configuration for existing plugin instances.

    Based on the nature of the schema updates, you might need this optional step 
    after updating the schema in {{site.konnect_short_name}} to make sure that any
    existing plugin entities are updated before the schemas are 
    changed in the Data Plane nodes.

1. Update the plugin schema on each Data Plane node.
1. Stop the migration/maintenance window.

{% endnavtab %}
{% endnavtabs %}

## Troubleshooting custom plugins in {{site.konnect_short_name}}

Common issues that you might encounter when working with custom plugins in {{site.konnect_short_name}}.

### Required field missing

**Issue:** You may see the error `unable to update running config: bad config received from Control Plane` with `required field missing`:

```sh
[lua] data_plane.lua:244: [clustering] unable to update running config: bad config received from Control Plane in 'plugins':
  - in entry 1 of 'plugins':
    in 'config':
      in 'ttl': required field missing, context: ngx.timer
```
{:.no-copy-code}

This means that a required field was removed from the schema on the Control Plane, but the schema on the Data Plane wasn't updated.
The Control Plane triggered a payload update and attempted to update the Data Plane, but ran into conflicts.

**Solution:** Make sure the Data Plane has an up-to-date schema.
