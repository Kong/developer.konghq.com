---
title: Licenses
content_type: reference
entities:
  - license

description: A {{site.base_gateway}} License entity allows you manage Enterprise licenses.

tier: enterprise

tools:
  - admin-api

api_specs:
  - gateway/admin-ee

schema:
  api: gateway/admin-ee
  path: /schemas/License

faqs: 
  - q: How do I troubleshoot the `license path environment variable not set` error?
    a: Neither the `KONG_LICENSE_DATA` nor the `KONG_LICENSE_PATH` environmental variables were defined, and no license file could be opened at the default license location (`/etc/kong/license.json`)
  - q: How do I troubleshoot the `internal error` error?
    a: An internal error has occurred while attempting to validate the License. Such cases are extremely unlikely. [Contact Kong support](https://support.konghq.com) to further troubleshoot.
  - q: How do I troubleshoot the `error opening license file` error?
    a: The license file defined either in the default location, or using the `KONG_LICENSE_PATH` env variable, couldn't be opened. Check that the user executing the Nginx process (e.g., the user executing the Kong CLI utility) has permissions to read this file.
  - q: How do I troubleshoot the `error reading license file` error?
    a: The license file defined either in the default location, or using the `KONG_LICENSE_PATH` env variable, could be opened, but an error occurred while reading. Confirm that the file isn't corrupt, that there are no kernel error messages reported (e.g., out of memory conditions, etc). This is a generic error and is extremely unlikely to occur if the file could be opened.
  - q: How do I troubleshoot the `could not decode license json` error?
    a: The license file data couldn't be decoded as valid JSON. Confirm that the file isn't corrupt and hasn't been altered since you received it from Kong. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com).
  - q: How do I troubleshoot the `invalid license format` error?
    a: The license file data is missing one or more key/value pairs. Confirm that the file isn't corrupt and hasn't been altered since you received it from Kong. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com).
  - q: How do I troubleshoot the `validation failed` error?
    a: The attempt to verify the payload of the License with the License's signature failed. Confirm that the file isn't corrupt and hasn't been altered since you received it from Kong. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com).
  - q: How do I troubleshoot the `license expired` error?
    a: The system time is past the License's `license_expiration_date`.
  - q: How do I troubleshoot the `invalid license expiration date` error?
    a: The data in the `license_expiration_date` field is incorrectly formatted. Try re-downloading and installing your license file from Kong. If you still receive this error after reinstallation, [contact Kong support](https://support.konghq.com).
---

## What is a License?

A License entity allows you configure a License in your {{site.base_gateway}} cluster, in both [traditional and hybrid mode deployments](/gateway/deployment-topologies/). {{site.base_gateway}} can be used with or without a License. A License is required to use [{{site.base_gateway}} Enterprise features](/gateway/enterprise-vs-oss/).

You will receive this file from Kong when you sign up for a
{{site.konnect_product_name}} Enterprise subscription. [Contact Kong](https://support.konghq.com) for more information. If you have purchased a subscription but haven’t received a license file, contact your sales representative.

## How to deploy a License

You can deploy a License in one of the following ways:

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
  - title: Description
    key: description
features:
  - title: |
      `/licenses` Admin API endpoint
    url: /gateway/entities/license/#deploy-a-license-with-the-licenses-admin-api-endpoint
    traditional: true
    hybrid: true
    dbless: false
    description: |
      The control plane sends Licenses configured through the `/licenses` endpoint to all data planes in the cluster. The data planes use the most recent `updated_at` License. This is the only method that applies the License to data planes automatically.
  - title: |
      File on the node filesystem (`license.json`)
    url: /gateway/entities/license/#deploy-a-license-with-a-file-on-the-node-filesystem-licensejson
    traditional: true
    hybrid: false
    dbless: true
    description: |
      The license data must contain straight quotes to be considered valid JSON (`'` and `"`, not `’` or `“`). Kong will search in the default location `/etc/kong/license.json`.
  - title: |
      Environment variable (`KONG_LICENSE_DATA` or `KONG_LICENSE_PATH`)
    url: /gateway/entities/license/#deploy-a-license-with-an-environment-variable
    traditional: true
    hybrid: false
    dbless: true
    description: |
      If you deploy a License using a `KONG_LICENSE_DATA` or `KONG_LICENSE_PATH` environment variable, the control plane **does not** propagate the License to data plane nodes. You **must** add the License to each data plane node, and each node **must** start with the License. The License can't be added after starting the node.<br><br> Note that unlike most other `KONG_*` environmental variables, the `KONG_LICENSE_DATA` and `KONG_LICENSE_PATH` cannot be defined in-line as part of any `kong` CLI commands. License file environmental variables must be exported to the shell in which the Nginx process will run, ahead of the `kong` CLI tool.
{% endfeature_table %}

<!--vale on-->

Keep the following in mind: 
* **Hybrid mode:** The license file must be deployed to each control plane and data plane node. Apply the License through the Kong Admin API to the control plane. The control plane distributes the License to its data plane nodes. This is the only method that applies the License to data planes automatically.
* **Traditional deployment with no separate control plane:** The license file must be deployed to each node running {{site.base_gateway}}.

License file checking is done independently by each node as the Kong process starts. No network connectivity is necessary to execute the license validation process.

Kong checks for a license file in the following order:

1. If present, the contents of the environmental variable `KONG_LICENSE_DATA` are used.
2. Kong will search in the default location `/etc/kong/license.json`.
3. If present, the contents of the file defined by the environment variable `KONG_LICENSE_PATH` is used.
4. Directly deploy a License using the `/licenses` Admin API endpoint.

### Deploy a License with the '/licenses' Admin API endpoint

{% entity_example %}
type: license
data:
  payload: "{\"license\":{\"payload\":{\"admin_seats\":\"1\",\"customer\":\"Example Company, Inc\",\"dataplanes\":\"1\",\"license_creation_date\":\"2017-07-20\",\"license_expiration_date\":\"2017-07-20\",\"license_key\":\"00141000017ODj3AAG_a1V41000004wT0OEAU\",\"product_subscription\":\"Konnect Enterprise\",\"support_plan\":\"None\"},\"signature\":\"6985968131533a967fcc721244a979948b1066967f1e9cd65dbd8eeabe060fc32d894a2945f5e4a03c1cd2198c74e058ac63d28b045c2f1fcec95877bd790e1b\",\"version\":\"1\"}}"
{% endentity_example %}

[Restart](/how-to/restart-kong-gateway-container/) the {{site.base_gateway}} nodes after adding or updating a License.

### Deploy a License with a file on the node filesystem ('license.json')

Save your License to a `license.json` file. The license data must contain straight quotes to be considered valid JSON (`'` and `"`, not `’` or `“`). Copy the license file to the `/etc/kong` directory.

### Deploy a License with an environment variable 

#### 'KONG_LICENSE_DATA'

Export your License to an environment variable (`export KONG_LICENSE_DATA='<license-contents-go-here>'`) and then include the `KONG_LICENSE_DATA` as part of the `docker run` command when starting a {{site.base_gateway}} container. The license data must contain straight quotes to be considered valid JSON
(`'` and `"`, not `’` or `“`).

#### 'KONG_LICENSE_PATH'

Include the License with `"KONG_LICENSE_PATH=/kong-license/license.json"` as part of the `docker run` command when starting a
{{site.base_gateway}} container. Mount the path to the file on your
local filesystem to a directory in the Docker container, making the file visible
from the container.

## License expiration

### Behavior

Licenses expire at 00:00 on the date of expiration, relative to the time zone the machine is running in.

Kong Manager displays a banner with a license expiration warning starting at 15 days before expiration.
Expiration warnings also appear in [{{site.base_gateway}} logs.

After the License expires, {{site.base_gateway}} behaves as follows:

* Kong Manager and its configuration are accessible and may be changed, however any Enterprise-specific features become read-only.
* The Admin API allows OSS features to continue working and configured {{site.ee_product_name}} features to continue operating in read-only mode.
* Proxy traffic, including traffic using Enterprise plugins, continues to be processed as if the License hadn't expired.
* Other Enterprise features aren't accessible.
* There may be some Enterprise features that are still writable, but they may also change later, so don't rely on this behavior.

The behavior of the different deployment modes is as follows:

- **Traditional:** Nodes will be able to restart/scale as needed.
- **Hybrid:** Existing data planes or new data planes **can accept** config from a control plane with an expired License.
- **DB-less and KIC:** New nodes **cannot** come up, restarts will break.

You can update your License with a `PUT` request to the [`/license/{license-id}` Admin API endpoint](/api/gateway/admin-ee/).

### Logs

{{site.base_gateway}} logs the License expiration date on the following schedule:
* 90 days before: `WARN` log entry once a day
* 30 days before: `ERR` log entry once a day
* At and after expiration: `CRIT` log entry once a day

## Monitor License usage and deployment information

A license report contains information about your {{site.base_gateway}} database-backed deployment, including License usage and deployment information. The license report module manually generates a report containing usage and deployment data by sending a request to the `/license/report` endpoint. Share this information with Kong Support to perform a health-check analysis of product utilization and overall deployment performance to ensure your organization is optimized with the best License and deployment plan for your needs.

The license report **does not**:
*   Automatically generate a report or send any data to any Kong servers
*   Track or generate any data other than the data that is returned in the response after you send a request to the endpoint

{:.important}
> **Important:** The license report functionality cannot be used in a DB-less deployment.

### Get a license report

| Method | Command |
|--------|----------|
| JSON | `curl -i -X GET http://localhost:8001/license/report` |
| TAR | `curl http://localhost:8001/license/report -o response.json && tar -cf report-$(date +"%Y_%m_%d_%I_%M_%p").tar response.json` |

Here's an example license report:

```json
{
   "counters": [
       {
           "bucket": "2021-12",
           "request_count": 0
       }
   ],
   "db_version": "postgres 9.6.19",
   "kong_version": "3.9.0.0",
   "license_key": "ASDASDASDASDASDASDASDASDASD_ASDASDA",
   "rbac_users": 0,
   "services_count": 0,
   "system_info": {
       "cores": 4,
       "hostname": "13b867agsa008",
       "uname": "Linux x86_64"
   },
   "workspaces_count": 1
}
```

### License report reference

The following table describes the different fields in a license report:

| Field             | Description                                                                                                                                                                                                 |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `counters`        | Counts the number of requests. <br><br> &#8226; `buckets`: Counts the number of requests made in a given month. <br><br> &#8729; `bucket`: Year and month when the requests were processed. If the value in `bucket` is `UNKNOWN`, then the requests were processed before {{site.base_gateway}} 2.7.0.1. <br> &#8729; `request_count`: Number of requests processed in the given month and year. <br><br> &#8226; `total_requests`: Number of requests processed in the `buckets`. i.e. `total_requests` is equivalent to adding up the `request_count` of each item in `buckets`. |
| `plugins_count`   | Counts the number of plugins in use. <br><br> &#8226; `tiers`: Separate counts by license tiers. <br><br> &#8729; `free`: Number of free plugins in use. <br> &#8729; `enterprise`: Number of enterprise plugins in use. <br> &#8729; `custom`: Number of custom plugins in use. <br><br> &#8226; `unique_route_lambdas`: Number of `awk-lambda` plugin in use. Only counts in case of the plugin is defined on a service-less route level and have a unique function name. <br> &#8226; `unique_route_kafkas`: Number of unique broker IPs listed in broker array across `kafka-upstream` plugin defined on a service-less route level. |
| `db_version`      | The type and version of the datastore {{site.base_gateway}} is using.                                                                                                                                       |
| `kong_version`    | The version of the {{site.base_gateway}} instance.                                                                                                                                                         |
| `license`         | Displays information about the current License running {{site.base_gateway}} instance. <br><br> &#8226; `license_expiration_date`: The date current License expires. If no License is present, the field displays as `2017-7-20`. <br> &#8226; `license_key`: Current license key. If no License is present, the field displays as `UNLICENSED`. |
| `rbac_users`      | The number of users registered with through RBAC.                                                                                                                                                         |
| `services_count`  | The number of configured services in the {{site.base_gateway}} instance.                                                                                                                                  |
| `routes_count`    | The number of configured routes in the {{site.base_gateway}} instance.                                                                                                                                   |
| `system_info`     | Displays information about the system running {{site.base_gateway}}. <br><br> &#8226; `cores`: Number of CPU cores on the node <br> &#8226; `hostname`: Encrypted system hostname <br> &#8226; `uname`: Operating system |
| `deployment_info` | Displays information about the deployment running {{site.base_gateway}}. <br><br> &#8226; `type`: Type of the deployment mode <br> &#8226; `connected_dp_count`: Number of dataplanes across the cluster. If the deployment isn't hybrid mode, the field isn't displayed. |
| `timestamp`       | Timestamp of the current response.                                                                                                                                                                         |
| `checksum`        | The checksum of the current report.                                                                                                                                                                        |
| `workspaces_count`| The number of workspaces configured in the {{site.base_gateway}} instance.                                                                                                                                 |



## Schema

{% entity_schema %}
