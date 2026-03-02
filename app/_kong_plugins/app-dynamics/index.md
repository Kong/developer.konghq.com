---
title: 'AppDynamics'
name: 'AppDynamics'

content_type: plugin
tier: enterprise
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

tags:
- analytics
- monitoring

categories:
  - analytics-monitoring

search_aliases:
  - app dynamics
  - app-dynamics

notes: | 
   **Dedicated Cloud Gateways**: This plugin is not supported in Dedicated or 
   Serverless Cloud Gateways because it depends on a local agent, and there are 
   no local nodes in Dedicated or Serverless Cloud Gateways.
---

This plugin integrates {{site.base_gateway}} with the [AppDynamics APM platform](https://www.splunk.com/en_us/products/splunk-appdynamics.html) so that
proxy requests handled by {{site.base_gateway}} can be identified and analyzed in
AppDynamics. 

The plugin reports request and response timestamps and error information to 
the AppDynamics platform to be analyzed in the AppDynamics flow map and correlated 
with other systems participating in handling application API requests.

{:.warning}
> **Important:** Unlike other {{site.base_gateway}} plugins, you must configure the AppDynamics plugin via environment variables. You must also install AppDynamics before using the plugin, and you must enable the plugin in your environment.

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

- If {{site.base_gateway}} is deployed on RHEL or CentOS, the `libappdynamics.so` file can be in the `/usr/lib64` directory, which is included in the default search path for shared libraries.
- If {{site.base_gateway}} is deployed on Debian or Ubuntu, the `libappdynamics.so` file can be in the `/usr/lib` directory, which is included in the default search path for shared libraries.
- If above options are not available, the `libappdynamics.so` file can be in one of the locations configured by the [system's shared library loader](https://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html).
- Alternatively, the `LD_LIBRARY_PATH` environment variable can be set to the directory containing the `libappdynamics.so` file when starting {{site.base_gateway}}.

## Enable the AppDynamics plugin

The AppDynamics plugin is not bundled in {{site.base_gateway}} packages by default. 
Before you configure the plugin, you must enable it:

* **Package install:** Set `plugins=bundled,app-dynamics` in [`kong.conf`](/gateway/configuration/#plugins) before starting {{site.base_gateway}}
* **Docker:** Set `export KONG_PLUGINS=bundled,app-dynamics` in the environment
* **Kubernetes:** Set `KONG_PLUGINS=bundled,app-dynamics` using the [Custom Plugin](/kubernetes-ingress-controller/custom-plugins/) instructions.

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

<!--vale off-->
{% table %}
columns:
  - title: Variable
    key: variable
  - title: Description
    key: description
  - title: Type
    key: type
  - title: Default
    key: default
rows:
  - variable: "`KONG_APPD_CONTROLLER_HOST`"
    description: "Hostname of the AppDynamics controller."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_PORT`"
    description: "Port number to use to communicate with the controller."
    type: "Integer"
    default: "`443`"
  - variable: "`KONG_APPD_CONTROLLER_ACCOUNT`"
    description: "Account name to use with the controller."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_ACCESS_KEY`"
    description: "Access key to use with the AppDynamics controller."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_LOGGING_LEVEL`"
    description: "Logging level of the AppDynamics SDK agent."
    type: "Integer"
    default: "`2`"
  - variable: "`KONG_APPD_LOGGING_LOG_DIR`"
    description: "Directory into which agent log files are written."
    type: "String"
    default: "`/tmp/appd`"
  - variable: "`KONG_APPD_TIER_NAME`"
    description: "Tier name to use for business transactions."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_APP_NAME`"
    description: "Application name to report to AppDynamics."
    type: "String"
    default: "`Kong`"
  - variable: "`KONG_APPD_NODE_NAME`"
    description: "Node name to report to AppDynamics. This value defaults to the system's hostname."
    type: "String"
    default: "`hostname`"
  - variable: "`KONG_APPD_INIT_TIMEOUT_MS`"
    description: "Maximum time to wait for a controller connection when starting, in milliseconds."
    type: "Integer"
    default: "`5000`"
  - variable: "`KONG_APPD_CONTROLLER_USE_SSL`"
    description: "Use SSL encryption in controller communication. `true`, `on`, or `1` are all interpreted as `True`, any other value is considered `false`."
    type: "Boolean"
    default: "`on`"
  - variable: "`KONG_APPD_CONTROLLER_HTTP_PROXY_HOST`"
    description: "Hostname of proxy to use to communicate with controller."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_HTTP_PROXY_PORT`"
    description: "Port number of controller proxy."
    type: "Integer"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_HTTP_PROXY_USERNAME`"
    description: "Username to use to identify to proxy. This value is a string that is never shown in logs. This value can be specified as a vault reference."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_HTTP_PROXY_PASSWORD`"
    description: "Password to use to identify to proxy. This value is a string that is never shown in logs. This value can be specified as a vault reference."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_CERTIFICATE_FILE`"
    description: |
       {% new_in 3.4.3.3 %} Path to a self-signed certificate file. For example, `/etc/kong/certs/ca-certs.pem`.
    type: "String"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_CERTIFICATE_DIR`"
    description: |
      {% new_in 3.4.3.3 %} Path to a certificate directory. For example, `/etc/kong/certs/`.
    type: "String"
    default: ""
  - variable: "`KONG_APPD_ANALYTICS_ENABLE`"
    description: |
      {% new_in 3.8 %} Enable or disable Analytics Agent reporting. When disabled (default), Analytics-related logging messages are suppressed.
    type: "Boolean"
    default: "`false`"
{% endtable %}
<!--vale on-->


### Possible values for the `KONG_APPD_LOGGING_LEVEL` parameter

The `KONG_APPD_LOGGING_LEVEL` environment variable is a numeric value that controls the desired logging level.
Each value corresponds to a specific level:

<!--vale off-->
{% table %}
columns:
  - title: Value
    key: value
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - value: "0"
    name: "`TRACE`"
    description: "Reports finer-grained informational events than the `debug` level, which may be useful to debug an application."
  - value: "1"
    name: "`DEBUG`"
    description: "Reports fine-grained informational events that may be useful to debug an application."
  - value: "2"
    name: "`INFO`"
    description: "Default log level. Reports informational messages that highlight the progress of the application at coarse-grained level."
  - value: "3"
    name: "`WARN`"
    description: "Reports on potentially harmful situations."
  - value: "4"
    name: "`ERROR`"
    description: "Reports on error events that may allow the application to continue running."
  - value: "5"
    name: "`FATAL`"
    description: "Fatal errors that prevent the agent from operating."
{% endtable %}
<!--vale on-->

## Agent logging

The AppDynamics agent sorts log information into separate log files, independent of {{site.base_gateway}} logs.
By default, log files are written to the `/tmp/appd` directory.
This location can be changed by setting the `KONG_APPD_LOGGING_LOG_DIR` environment variable.

If problems occur with the AppDynamics integration, inspect the AppDynamics agent's log files in addition to the {{site.base_gateway}} logs.

{:.warning}
> **Important:** ARM isn't supported when using the AppDynamics agent. The agent only supports x86 architecture.

## AppDynamics node name considerations

The AppDynamics plugin sets the `KONG_APPD_NODE_NAME` to the local hostname by default, which typically reflects the container ID of the containerized application. 
Multiple instances of the AppDynamics agent must use different node names, and one agent must exist for each of {{site.base_gateway}}'s worker processes, where the node name is suffixed by the worker ID. 
This results in multiple nodes being created for each {{site.base_gateway}} instance, one for each worker process.

