---
title: Licenses
content_type: reference
entities:
  - license

description: A {{site.base_gateway}} License entity allows you manage on-prem Enterprise licenses.

tools:
  - admin-api

api_specs:
  - gateway/admin-ee

related_resources:
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/

schema:
  api: gateway/admin-ee
  path: /schemas/License


faqs: 
  - q: How do I make sure the License is deployed to data plane nodes correctly in hybrid mode?
    a: In hybrid mode, the license file must be deployed to each control plane and data plane node. As long as you deploy the License with the [`/licenses` Admin API endpoint](/api/gateway/admin-ee/#/operations/post-licenses), the control plane automatically applies the License to its data plane nodes. 
  - q: What happens to the license file in traditional mode when there are no separate control planes? 
    a: The license file must be manually deployed to each node running {{site.base_gateway}}.
---

## What is a License?

A License entity allows you configure a License in your on-prem {{site.base_gateway}} cluster, in both [traditional and hybrid mode deployments](/gateway/deployment-topologies/). {{site.base_gateway}} can be used with or without a License. 

You receive a license file when you sign up for a {{site.base_gateway}} Enterprise subscription. If you purchased a subscription but haven’t received a license file, contact your sales representative.

Kong checks for a license in the following order:

1. The contents of the environmental variable `KONG_LICENSE_DATA`
2. The default location `/etc/kong/license.json`
3. The contents of the file defined by the `KONG_LICENSE_PATH` environment variable
4. A License directly deployed with the [`/licenses` Admin API endpoint](/api/gateway/admin-ee/#/operations/post-licenses).

Each node independently checks for the license file when the {{site.base_gateway}} process starts. Network connectivity isn't required for license validation.

## Deployment methods

Licenses are deployed according to your deployment topology: 

<!--vale off-->

{% feature_table %}
item_title: Method
columns:
  - title: Traditional database-backed
    key: traditional
  - title: Hybrid mode
    key: hybrid
  - title: DB-less mode
    key: dbless
features:
  - title: Admin API
    url: /api/gateway/admin-ee/#/operations/post-licenses
    traditional: true
    hybrid: true
    dbless: false
  - title: License File
    url: /gateway/entities/license/#deploy-a-license-with-a-file-on-the-node-filesystem-licensejson
    traditional: true
    hybrid: true
    dbless: true
  - title: Environment variable
    url: /gateway/entities/license/#deploy-a-license-with-an-environment-variable
    traditional: true
    hybrid: true
    dbless: true
{% endfeature_table %}

<!--vale on-->


## Deploy a License

{% navtabs %}
{% navtab "Admin API" %}

You can deploy a License using the Admin API.

The control plane sends Licenses configured through the [`/licenses` endpoint](/api/gateway/admin-ee/#/operations/post-licenses) to all data planes in the cluster. The data planes use the most recent `updated_at` License. This is the only method that automatically applies the License to data planes.

{% entity_example %}
type: license
data:
  payload: "{\"license\":{\"payload\":{\"admin_seats\":\"1\",\"customer\":\"Example Company, Inc\",\"dataplanes\":\"1\",\"license_creation_date\":\"2017-07-20\",\"license_expiration_date\":\"2017-07-20\",\"license_key\":\"00141000017ODj3AAG_a1V41000004wT0OEAU\",\"product_subscription\":\"Konnect Enterprise\",\"support_plan\":\"None\"},\"signature\":\"6985968131533a967fcc721244a979948b1066967f1e9cd65dbd8eeabe060fc32d894a2945f5e4a03c1cd2198c74e058ac63d28b045c2f1fcec95877bd790e1b\",\"version\":\"1\"}}"
{% endentity_example %}

{% endnavtab %}
{% navtab "license.json" %}

You can deploy a License with a `license.json` file.

The license data must contain straight quotes to be considered valid JSON (`'` and `"`, not `’` or `“`). Kong searches for the License by default in `/etc/kong/license.json`.

{:.info}
> The control plane **does not** propagate the License to data plane nodes. 
You **must** add the License to each data plane node, and each node **must** start with the License. 
The License can't be added after starting the node.

1. Save your License to a file named `license.json`.  
1. Copy the license file to the `/etc/kong`.
1. [Restart](/how-to/restart-kong-gateway-container/) the {{site.base_gateway}} nodes to apply the license by running `kong restart` from within the container.
{% endnavtab %}
{% navtab "Environment variable" %}

You can deploy a License as an environment variable.

{:.info}
> If you deploy a License using a `KONG_LICENSE_DATA` or `KONG_LICENSE_PATH` environment variable, the control plane **does not** propagate the License to data plane nodes. 
You **must** add the License to each data plane node, and each node **must** start with the License. 
The License can't be added after starting the node.

Unlike other `KONG_*` environmental variables, the `KONG_LICENSE_DATA` and `KONG_LICENSE_PATH` can't be defined in-line as part of any `kong` CLI commands. License file environmental variables must be exported to the shell where the Nginx process runs, ahead of the `kong` CLI tool.

1. Export your License to an environment variable: 
  ```sh
  export KONG_LICENSE_DATA=$YOUR_LICENSE_DATA
  ```
1. Reference the variable as part of your {{site.base_gateway}} deployment.

By default, {{site.base_gateway}} looks for a License file at `/etc/kong/license.json`. If your default {{site.base_gateway}} directory is different, or the location of `license.json` is different than the default, you can use the `KONG_LICENSE_PATH` variable instead to force {{site.base_gateway}} to check a different directory.
{% endnavtab %}
{% endnavtabs %}

## Expiration

Licenses expire at midnight on the expiration date. The expiration time is the same as that of the time zone of your control plane.

[Kong Manager](/gateway/kong-manager/) warns you of your license expiring 15 days before it expires. {{site.base_gateway}} logs also show a license expiration alert 90 and 30 days before the license expires as well as on and after the expiration date.

After a License expires, {{site.base_gateway}} behaves as follows:

* All configured Enterprise-specific features become read-only
* You can't configure additional Enterprise features
* You can continue to access Kong Manager and change its configuration
* You can continue to use OSS features via the Admin API
* All proxy traffic, including Enterprise plugin traffic, continues to be processed as if the License wasn't expired
* You can still restart and scale nodes in traditional mode
* Data planes can still accept config from a control plane with an expired license in hybrid mode
* New nodes can't come up and restarts will break in DB-less mode and KIC

You can update your License with a `PUT` request to the [`/license/{license-id}` Admin API endpoint](/api/gateway/admin-ee/#/operations/put-licenses-license-id).

## License reports

A license report contains information about your {{site.base_gateway}} database-backed deployment, including License usage and deployment information. You can generate a license report by sending a request to the [`/license/report` endpoint](/api/gateway/admin-ee/#/operations/get-license-report). You can't automatically generate a license report and the report doesn't send data to Kong servers. License reports aren't supported in a DB-less deployment.

You can share the report with Kong Support to perform a health-check analysis of product usage and overall deployment performance to ensure your organization is optimized with the best License and deployment plan for your needs.


## Common errors

| Error | Description |
|-------|-------------|
| `license path environment variable not set` | The `KONG_LICENSE_DATA` or `KONG_LICENSE_PATH` environment variables weren't defined. No license file could be opened at the default license location (`/etc/kong/license.json`). |
| `error opening license file` | The license file defined either in the default location, or using the `KONG_LICENSE_PATH` env variable, couldn't be opened. Check that the user executing the Nginx process (e.g., the user executing the Kong CLI utility) has permissions to read this file. |
| `error reading license file` | The license file defined either in the default location, or using the `KONG_LICENSE_PATH` env variable, could be opened, but an error occurred while reading it. Confirm that the file isn't corrupt, and that there are no kernel error messages reported (e.g., out of memory conditions, etc). |
| `could not decode license json` | The license file data couldn't be decoded as valid JSON. Confirm that the file isn't corrupt and hasn't been altered since you received it from Kong. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com). |
| `invalid license format` | The license file data is missing one or more key/value pairs. Confirm that the file isn't corrupt and hasn't been altered since you received it from Kong. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com). |
| `validation failed` | Verifying the payload of the License with the License's signature failed. Confirm that the file isn't corrupt and hasn't been altered since you received it from Kong. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com). |
| `license expired` | This error displays when the system time is past the License's `license_expiration_date`. [Contact Kong support](https://support.konghq.com) for a new license. |
| `invalid license expiration date` | The data in the `license_expiration_date` field is incorrectly formatted. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com). |

## Schema

{% entity_schema %}
