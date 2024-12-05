A plugin which is not associated to any service, route, consumer, or consumer group is considered global, and will be run on every request.

* In self-managed {{site.ee_product_name}}, the plugin applies to every entity in a given workspace.
* In self-managed {{site.base_gateway}} (OSS), the plugin applies to your entire environment.
* In Konnect, the plugin applies to every entity in a given control plane.

Read the [Plugin Reference](/api/gateway/admin-ee/#/operations/list-plugins-with-consumer) and the [Plugin Precedence](/plugins/precedence/)
sections for more information. 
