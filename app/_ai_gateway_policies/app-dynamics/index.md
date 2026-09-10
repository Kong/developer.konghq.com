---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: Integrate {{site.ai_gateway}} with the AppDynamics APM Platform
---

This policy integrates {{site.ai_gateway}} with the [AppDynamics APM platform](https://www.splunk.com/en_us/products/splunk-appdynamics.html) so that requests handled by {{site.base_gateway}} can be identified and analyzed in AppDynamics.

The AppDynamics policy reports request and response timestamps and error information to the AppDynamics platform to be analyzed in the AppDynamics flow map and correlated with other systems participating in handling application API requests.

{:.warning}
> **Important:** Unlike other {{site.ai_gateway}} policies, you must configure the AppDynamics policy via environment variables. You must also install AppDynamics before using the policy, and you must enable the policy in your environment.

## AppDynamics installation prerequisites

Before using the policy, download the [AppDynamics C/C++ SDK](https://help.splunk.com/en/appdynamics-saas/application-performance-monitoring/26.8.0/install-app-server-agents/cc-sdk) on the machine or within the container running the {{site.base_gateway}} data plane. To use the AppDynamics policy, the `libappdynamics.so` shared library must be available on all data plane nodes running {{site.ai_gateway}}. You can install the AppDynamics C/C++ SDK or extract the `libappdynamics.so` shared library, which is the only required file.

For information about installation and configuration, see the [AppDynamics Saas](https://help.splunk.com/en/appdynamics-saas) and [AppDynamics On-Premises](https://help.splunk.com/en/appdynamics-on-premises) documentation.

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