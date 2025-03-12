---
title: 'AppDynamics'
name: 'AppDynamics'

content_type: plugin

publisher: kong-inc
description: 'Integrate {{site.base_gateway}} with the AppDynamics APM Platform'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid

icon: app-dynamics.png

categories:
  - analytics
  - monitoring

search_aliases:
  - app dynamics
  - app-dynamics
---

This plugin integrates {{site.base_gateway}} with the [AppDynamics APM platform](https://www.splunk.com/en_us/products/splunk-appdynamics.html) so that
proxy requests handled by {{site.base_gateway}} can be identified and analyzed in
AppDynamics. 

The plugin reports request and response timestamps and error information to 
the AppDynamics platform to be analyzed in the AppDynamics flow map and correlated 
with other systems participating in handling application API requests.

{:.warning}
> **Important:** Unlike other {{site.base_gateway}} plugins, you must configure the AppDynamics plugin via environment variables. You must also install AppDynamics before using the plugin.

## AppDynamics installation prerequisites

Before using the plugin, download and install the AppDynamics C/C++ Application Agent and SDK on [Linux](https://docs.appdynamics.com/appd/23.x/latest/en/application-monitoring/install-app-server-agents/c-c++-sdk/install-the-c-c++-sdk-on-linux) or [Windows](https://docs.appdynamics.com/appd/23.x/latest/en/application-monitoring/install-app-server-agents/c-c++-sdk/install-the-c-c++-sdk-on-windows) on the machine or within the container running {{site.base_gateway}}. To use the AppDynamics plugin in {{site.base_gateway}}, the AppDynamics C/C++
SDK must be installed on all nodes running {{site.base_gateway}}. The `libappdynamics.so` shared
library file is the only required file.

For information about supported environments, see the [AppDynamics C/C++ SDK Supported Environments](https://docs.appdynamics.com/appd/23.x/latest/en/application-monitoring/install-app-server-agents/c-c++-sdk/c-c++-sdk-supported-environments) documentation.

### Recommended installation

If you are using {{site.base_gateway}} 3.0.0.0 or later, we recommended installing the `libappdynamics.so` in the `/usr/local/kong/lib` directory.
This directory is included in the {{site.base_gateway}} search path for shared libraries, so the `libappdynamics.so` file will be found automatically.

### Alternative installation

If you are using an older version of {{site.base_gateway}}, or if you prefer to install the `libappdynamics.so` file in a different location, you can do so.

- If {{site.base_gateway}} is deployed in RHEL or CentOS, the `libappdynamics.so` file can be in the `/usr/lib64` directory, which is included in the default search path for shared libraries.
- If {{site.base_gateway}} is deployed in Debian or Ubuntu, the `libappdynamics.so` file can be in the `/usr/lib` directory, which is included in the default search path for shared libraries.
- If above options are not available, the `libappdynamics.so` file can be in one of the locations configured by the [system's shared library loader](https://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html).
- Alternatively, the `LD_LIBRARY_PATH` environment variable can be set to the directory containing the `libappdynamics.so` file when starting {{site.base_gateway}}.

## Enable the AppDynamics plugin

Before you configure the plugin, you must enable it:

* **Package install:** Set `plugins=bundled,app-dynamics` in [`kong.conf`](/gateway/configuration/) before starting {{site.base_gateway}}
* **Docker:** Set `export KONG_PLUGINS=bundled,app-dynamics` in the environment
* **Kubernetes:** Set `KONG_PLUGINS=bundled,app-dynamics` using these instructions

## Plugin configuration

The AppDynamics plugin is configured through environment variables
that must be set when {{site.base_gateway}} is started. The AppDynamics plugin makes use of the AppDynamics C/C++ SDK to send
information to the AppDynamics controller. See the
[AppDynamics C/C++ SDK documentation](https://docs.appdynamics.com/appd/23.x/latest/en/application-monitoring/install-app-server-agents/c-c++-sdk/use-the-c-c++-sdk)
for more information about the configuration parameters.

{:.info}
> All non-default environment variables in the table **must** be set.

The plugin uses the following environment
variables:

| Variable | Description | Type | Default |
|--|--|--|--|
| `KONG_APPD_CONTROLLER_HOST` | Hostname of the AppDynamics controller. | String | |
| `KONG_APPD_CONTROLLER_PORT` | Port number to use to communicate with the controller. | Integer | `443` |
| `KONG_APPD_CONTROLLER_ACCOUNT` | Account name to use with controller. | String | |
| `KONG_APPD_CONTROLLER_ACCESS_KEY` | Access key to use with the AppDynamics controller. | String |
| `KONG_APPD_LOGGING_LEVEL` | Logging level of the AppDynamics SDK agent. | Integer | `2` |
| `KONG_APPD_LOGGING_LOG_DIR` | Directory into which agent log files are written. | String | `/tmp/appd` |
| `KONG_APPD_TIER_NAME` | Tier name to use for business transactions. | String | |
| `KONG_APPD_APP_NAME` | Application name to report to AppDynamics. | String | `Kong` |
| `KONG_APPD_NODE_NAME` | Node name to report to AppDynamics. This value defaults to the system's hostname.| String | `hostname` |
| `KONG_APPD_INIT_TIMEOUT_MS` | Maximum time to wait for a controller connection when starting, in milliseconds. | Integer | `5000` |
| `KONG_APPD_CONTROLLER_USE_SSL` | Use SSL encryption in controller communication. `true`, `on`, or `1` are all interpreted as `True`, any other value is considered `false`.| Boolean | `on` |
| `KONG_APPD_CONTROLLER_HTTP_PROXY_HOST` | Hostname of proxy to use to communicate with controller. | String |  |
| `KONG_APPD_CONTROLLER_HTTP_PROXY_PORT` | Port number of controller proxy. | Integer |  |
| `KONG_APPD_CONTROLLER_HTTP_PROXY_USERNAME` | Username to use to identify to proxy. This value is a string that is never shown in logs. This value can be specified as a vault reference.| String |  |
| `KONG_APPD_CONTROLLER_HTTP_PROXY_PASSWORD` | Password to use to identify to proxy. This value is a string that is never shown in logs. This value can be specified as a vault reference.| String |  |
| `KONG_APPD_CONTROLLER_CERTIFICATE_FILE` | Path to a self-signed certificate file. For example, `/etc/kong/certs/ca-certs.pem`. <br><br>_Available starting in {{site.base_gateway}} 3.4.3.3_ | String | | 
| `KONG_APPD_CONTROLLER_CERTIFICATE_DIR` | Path to a certificate directory. For example, `/etc/kong/certs/`. <br><br> _Available starting in {{site.base_gateway}} 3.4.3.3_ | String | | 
| `KONG_APPD_CONTROLLER_CERTIFICATE_FILE` | Path to a self-signed certificate file. For example, `/etc/kong/certs/ca-certs.pem`. <br><br>_Available starting in {{site.base_gateway}} 3.6.x_ | String | | 
| `KONG_APPD_CONTROLLER_CERTIFICATE_DIR` | Path to a certificate directory. For example, `/etc/kong/certs/`. <br><br>_Available starting in {{site.base_gateway}} 3.6.x_ | String | | 
| `KONG_APPD_ANALYTICS_ENABLE` | Enable or disable Analytics Agent reporting. When disabled (default), Analytics-related logging messages are suppressed. <br><br>_Available starting in {{site.base_gateway}} 3.8.x_ | Boolean | `false` | 

### Possible values for the `KONG_APPD_LOGGING_LEVEL` parameter

The `KONG_APPD_LOGGING_LEVEL` environment variable is a numeric value that controls the desired logging level.
Each value corresponds to a specific level:

| Value | Name | Description |
|--|--|--|
| 0 | `TRACE` | Reports finer-grained informational events than the debug level that may be useful to debug an application. |
| 1 | `DEBUG` | Reports fine-grained informational events that may be useful to debug an application. |
| 2 | `INFO` | Default log level. Reports informational messages that highlight the progress of the application at coarse-grained level.|
| 3 | `WARN` | Reports on potentially harmful situations. |
| 4 | `ERROR` | Reports on error events that may allow the application to continue running.|
| 5 | `FATAL` | Fatal errors that prevent the agent from operating. |

## Agent logging

The AppDynamics agent sorts log information into separate log files, independent of {{site.base_gateway}}.
By default, log files are written to the `/tmp/appd` directory.
This location can be changed by setting the `KONG_APPD_LOGGING_LOG_DIR` environment variable.

If problems occur with the AppDynamics integration, inspect the AppDynamics agent's log files in addition to the {{site.base_gateway}} logs.

## AppDynamics node name considerations

The AppDynamics plugin sets the `KONG_APPD_NODE_NAME` to the local
host name by default, which typically reflects the container ID of the containerized
application. Multiple instances of the AppDynamics agent must use
different node names, and one agent must exists for each of {{site.base_gateway}}'s
worker processes, the node name is suffixed by the worker ID. This
results in multiple nodes being created for each {{site.base_gateway}}
instance, one for each worker process.

