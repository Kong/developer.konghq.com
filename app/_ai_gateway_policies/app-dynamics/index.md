---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: Integrate {{site.ai_gateway}} with the AppDynamics APM Platform
tags:
- analytics
- monitoring
categories:
  - analytics-monitoring
search_aliases:
  - app dynamics
  - app-dynamics
related_resources:
  - text: "OpenTelemetry Policy"
    url: /ai-gateway/policies/opentelemetry/
---

This policy integrates {{site.ai_gateway}} with the [AppDynamics APM platform](https://www.splunk.com/en_us/products/splunk-appdynamics.html) so that requests handled by {{site.ai_gateway}} can be identified and analyzed in AppDynamics.

The AppDynamics policy reports request and response timestamps and error information to the AppDynamics platform to be analyzed in the AppDynamics flow map and correlated with other systems.

{:.warning}
> **Important:** Unlike other {{site.ai_gateway}} policies, you must configure the AppDynamics policy via environment variables. You must also install AppDynamics before using the policy, and you must enable the policy in your environment.

## AppDynamics installation prerequisites

Before using the policy, download the [AppDynamics C/C++ SDK](https://help.splunk.com/en/appdynamics-saas/application-performance-monitoring/26.8.0/install-app-server-agents/cc-sdk) on the machine or within the container running the {{site.base_gateway}} data plane. To use the AppDynamics policy, the `libappdynamics.so` shared library must be available on all data plane nodes running {{site.ai_gateway}}. You can install the AppDynamics C/C++ SDK or extract the `libappdynamics.so` shared library, which is the only required file.

For information about installation and configuration, see the [AppDynamics SaaS](https://help.splunk.com/en/appdynamics-saas) and [AppDynamics On-Premises](https://help.splunk.com/en/appdynamics-on-premises) documentation.

### Recommended installation

We recommended installing the `libappdynamics.so` in the `/usr/local/kong/lib` directory. This directory is included in the {{site.ai_gateway}} search path for shared libraries, so the `libappdynamics.so` file will be found automatically.

When using the quickstart container perform the following steps:

1. Extract the SDK.

   ```sh
   tar -xzf appdynamics-sdk-native-64bit-linux-VERSION.tgz
   ```
2. Locate the library file.

   ```sh
   cd appdynamics-cpp-sdk/lib
   ```
3. Copy the file into the container running the {{site.ai_gateway}} dataplane.

   ```sh
   docker cp libappdynamics.so <container_id>:/usr/local/kong/lib
   ```

### Alternative installation

If you prefer to install the `libappdynamics.so` file in a different location, you can do so.

- If {{site.ai_gateway}} is deployed on RHEL or CentOS, the `libappdynamics.so` file can be in the `/usr/lib64` directory, which is included in the default search path for shared libraries.
- If {{site.ai_gateway}} is deployed on Debian or Ubuntu, the `libappdynamics.so` file can be in the `/usr/lib` directory, which is included in the default search path for shared libraries.
- If above options are not available, the `libappdynamics.so` file can be in one of the locations configured by the [system's shared library loader](https://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html).
- Alternatively, the `LD_LIBRARY_PATH` environment variable can be set to the directory containing the `libappdynamics.so` file when starting {{site.base_gateway}}.

## Enable the AppDynamics policy

The AppDynamics policy is not bundled in {{site.ai_gateway}} packages by default. Before you configure the plugin, you must enable it:

- **Docker:** Set `export KONG_PLUGINS=bundled,app-dynamics` in the environment
- **Kubernetes:** Set `KONG_PLUGINS=bundled,app-dynamics` using the [Custom Plugin](/kubernetes-ingress-controller/custom-plugins/) instructions.

## AppDynamics policy configuration

The AppDynamics policy is configured through environment variables that must be set when {{site.ai_gateway}} is started. The AppDynamics policy makes use of the AppDynamics C/C++ SDK to send information to the AppDynamics controller. See the [AppDynamics C/C++ SDK documentation](https://help.splunk.com/en/appdynamics-saas/application-performance-monitoring/26.8.0/install-app-server-agents/cc-sdk/use-the-cc-sdk) for more information about the configuration parameters.

{:.info}
> All non-default environment variables in the table **must** be set.

The policy uses the following environment variables:

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
    description: "Path to a self-signed certificate file. For example, `/etc/kong/certs/ca-certs.pem`."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_CONTROLLER_CERTIFICATE_DIR`"
    description: "Path to a certificate directory. For example, `/etc/kong/certs/`."
    type: "String"
    default: ""
  - variable: "`KONG_APPD_ANALYTICS_ENABLE`"
    description: "Enable or disable Analytics Agent reporting. When disabled (default), Analytics-related logging messages are suppressed."
    type: "Boolean"
    default: "`false`"
{% endtable %}
<!--vale on-->

### Possible values for the `KONG_APPD_LOGGING_LEVEL` parameter

The `KONG_APPD_LOGGING_LEVEL` environment variable is a numeric value that controls the desired logging level.

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

The AppDynamics agent sorts log information into separate log files, independent of {{site.ai_gateway}} logs. By default, log files are written to the `/tmp/appd` directory. This location can be changed by setting the `KONG_APPD_LOGGING_LOG_DIR` environment variable.

If problems occur with the AppDynamics integration, inspect the AppDynamics agent's log files in addition to the {{site.ai_gateway}} logs.

{:.warning}
> **Important:** ARM isn't supported by the AppDynamics agent. The agent only supports x86 architecture.

## AppDynamics node name considerations

The AppDynamics policy sets the `KONG_APPD_NODE_NAME` to the local hostname by default, which typically reflects the container ID of the containerized application. Multiple instances of the AppDynamics agent must use different node names, and one agent must exist for each of {{site.ai_gateway}}'s worker processes, where the node name is suffixed by the worker ID. This results in multiple nodes being created for each {{site.ai_gateway}} instance, one for each worker process.