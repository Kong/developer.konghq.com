* Workspaces are supported on hybrid and Dedicated Cloud control planes. They aren't supported on serverless control planes, {{site.kic_product_name}} control planes, or control planes that belong to a [control plane group](/gateway/control-plane-groups/). A control plane can't be both Workspace-enabled and a member of a control plane group.
* [{{site.ai_gateway}} 2.x](/ai-gateway/) doesn't support Workspaces. AI plugins, such as AI Proxy and AI Proxy Advanced, work inside a Workspace when running on a standard {{site.base_gateway}} control plane.
* {{site.konnect_short_name}} doesn't report analytics per Workspace. Analytics for a control plane include traffic from every Workspace in it.
* Collision detection always uses an exact match on path, method, host, and SNI. The configurable "smart" collision strategies available for {{site.base_gateway}} aren't available for Workspaces.
* A plugin or Consumer configured in one Workspace applies only to that Workspace. {{site.konnect_short_name}} doesn't support sharing a plugin or Consumer configuration across Workspaces.
* Workspace names can't be changed. To rename one, create a new Workspace and use decK to sync the configuration to it.
* Custom plugin schemas can only be uploaded to `default`. The Workspace Plugin Admin role can use an existing schema but can't upload one.
* A control plane doesn't list Workspaces until the first named Workspace is created, so roles on `default` can't be assigned before then.
* If you want to assign roles on every Workspace at the same time, you must use the API with the scope `[cp, *]`. 
* A Workspace role on `default` doesn't apply to decK, Terraform, or the public API, because they use the control plane path. Those tools need a control plane role.
* Plugins in a named Workspace can only use partials, including Redis configurations, created in that same Workspace. Partials on the parent control plane aren't available to other Workspaces, so a Redis configuration must be created again in each Workspace that needs it. Managed cache for {{site.konnect_short_name}} Dedicated Cloud Gateways can't be used from a named Workspace yet.
* decK writes the control plane's CA certificate into every Workspace file, so removing it from one file deletes it for the whole control plane.
* kongctl and the {{site.konnect_short_name}} MCP server don't support Workspaces yet.
* An [API](/catalog/apis/) can't be linked to a [Gateway Service](/gateway/entities/service/) in a named Workspace. Linking the whole control plane works, but the [ACE plugin](/plugins/ace/) must be added to each Workspace that serves the API, because global plugins in `default` don't apply to other Workspaces.
* When you move an API between Workspaces with Routes, expect downtime. This is because collision detection rejects the new Route until the old one is removed.
