---
title: Installation and distribution of custom plugins
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn about the different ways to deploy a custom plugin.

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
---

Custom plugins for {{site.base_gateway}} consist of Lua source files that need to be in the file system of each of your {{site.base_gateway}} nodes. 
This guide will provide you with step-by-step instructions that will make a {{site.base_gateway}} node aware of your custom plugin(s).

These steps should be applied to each node in your {{site.base_gateway}} cluster, to ensure the custom plugins are available on each one of them.

## Package sources

To package your custom plugin code, we recommend LuaRocks, as it is installed along with {{site.base_gateway}} when using one of the official distribution packages. 
However, you can also use a regular packing strategy, such as `tar`.

When using LuaRocks, you must create a `rockspec` file, which specifies the package contents. 
For an example, see the [{{site.base_gateway}} plugin template](https://github.com/Kong/kong-plugin). 
For more information about the format, see the LuaRocks [documentation on rockspecs](https://github.com/keplerproject/luarocks/wiki/Creating-a-rock).

Pack your rock using the following commands (from the plugin repo):

1. Install it locally (based on the `.rockspec` in the current directory):
    ```sh
    luarocks make
    ```

2. Pack the installed rock:
   ```sh
   luarocks pack {plugin-name} {version}
   ```
   This creates a `.rock` file.

   {:.warning}
   > **Important:** `luarocks pack` is dependent on the `zip` utility being installed. More recent images of {{site.base_gateway}} have been hardened, and utilities such as `zip` are no longer available. If this is being performed as part of a custom Docker image, ensure `zip` is installed before running this command.

To do this without LuaRocks, use `tar` to pack the `.lua` plugin files into a `.tar.gz` archive. 
You can also include the `.rockspec` file if you do have LuaRocks on the target systems.

The contents of this archive should look like this:
```
tree {plugin-name}
{plugin-name}
├── INSTALL.txt
├── README.md
├── kong
│   └── plugins
│       └── {plugin-name}
│           ├── handler.lua
│           └── schema.lua
└── {plugin-name}-{version}.rockspec
```
{:.no-copy-code}

## Install the plugin

For a {{site.base_gateway}} node to be able to use the custom plugin, the custom plugin's Lua sources must be installed on your host's file system. 
You can do this with LuaRocks, Docker, or manually.

Regardless of which method you are using to install your plugin's sources, you must install it for each node in your {{site.base_gateway}} cluster.

### Via LuaRocks from the created rock

The `.rock` file is a self contained package that can be installed locally or from a remote server.

If the `luarocks` utility is installed in your system, you can install the rock in your LuaRocks tree:
```sh
luarocks install {rock-filename}
```

The filename can be a local name, or any of the supported methods, for example `http://myrepository.lan/rocks/my-plugin-0.1.0-1.all.rock`.

### Via LuaRocks from the source archive

If the `luarocks` utility is installed in your system, you can install the Lua sources in your LuaRocks tree:
```sh
cd {plugin-name}
luarocks make
```

This will install the Lua sources in `kong/plugins/{plugin-name}` in your system's LuaRocks tree, where all the {{site.base_gateway}} sources are already present.

### Via a Dockerfile or docker run (install and load)

If you are running {{site.base_gateway}} on Docker or Kubernetes, the plugin needs to be installed inside the {{site.base_gateway}} container. 
Copy or mount the plugin’s source code into the container.

{:.info}
> **Note:** Official {{site.base_gateway}} images are configured to run  as the `nobody` user.
> When building a custom image, you must temporarily set the user to `root` to copy files into the {{site.base_gateway}} image.

Here's an example Dockerfile that shows how to mount your plugin in the {{site.base_gateway}} image:
```dockerfile
FROM kong/kong-gateway:latest

# Ensure any patching steps are executed as root user
USER root

# Add custom plugin to the image
COPY example-plugin/kong/plugins/example-plugin /usr/local/share/lua/5.1/kong/plugins/example-plugin
ENV KONG_PLUGINS=bundled,example-plugin

# Ensure kong user is selected for image execution
USER kong

# Run kong
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]
``` 

You can also include the following in your `docker run` command:
```sh
-v "{custom_plugin_folder}:/tmp/custom_plugins/kong" 
-e "KONG_LUA_PACKAGE_PATH=/tmp/custom_plugins/?.lua;;"
-e "KONG_PLUGINS=bundled,example-plugin"
```

### Manually

To avoid polluting the LuaRocks tree, you can point {{site.base_gateway}} to the directory containing the plugins.

You can do that with the [`lua_package_path`](/gateway/configuration/#lua-package-path) property of your {{site.base_gateway}} configuration.

Those properties contain a semicolon-separated list of directories in which to search for Lua sources:
```
lua_package_path = /{path-to-plugin-location}/?.lua;;
```

In this example:
* `/{path-to-plugin-location}` is the path to the directory containing the extracted archive. 
  Replace it with the location of the `kong` directory from the archive.
* `?` is a placeholder that will be replaced by `kong.plugins.{plugin-name}` when {{site.base_gateway}} tries to load your plugin. 
  Do not change it.
* `;;` a placeholder for the default Lua path. Do not change it.

For example, if the plugin `something` is located on the file system and the handler file is located at `/usr/local/custom/kong/plugins/something/handler.lua`, the path setup is:
```
lua_package_path = /usr/local/custom/?.lua;;
```

#### Multiple plugins

If you want to install two or more custom plugins this way, you can set the variable to something like:
```
lua_package_path = /path/to/plugin1/?.lua;/path/to/plugin2/?.lua;;
```

In this example:
* `;` is the separator between directories.
* `;;` still means refers to the default Lua path.

You can also set this property via its environment variable equivalent: `KONG_LUA_PACKAGE_PATH`.

## Load the plugin

1. Add the custom plugin's name to the [`plugins`](/gateway/configuration/#plugins) list in your {{site.base_gateway}} configuration:

   ```
   plugins = bundled,<plugin-name>
   ```

   If you are using two or more custom plugins, insert commas in between:
   ```
   plugins = bundled,plugin1,plugin2
   ```
   
   If you don't want to include the bundle plugins, you can remove `bundled`.

   You can also set this property via its environment variable equivalent `KONG_PLUGINS`.

1. Make the same update for each node in your {{site.base_gateway}} cluster.

1. Restart {{site.base_gateway}} to apply the plugin:
    ```
    kong restart
    ```
    
    Or, if you want to apply a plugin without stopping {{site.base_gateway}}:
    ```
    kong prepare
    kong reload
    ```

## Check that the plugin is loaded

To make sure your plugin is being loaded by {{site.base_gateway}}, you can start {{site.base_gateway}} with the [`log_level`](/gateway/configuration/#log-level) parameter set to `debug`:
```
log_level = debug
```

Then, you should see the following log for each plugin being loaded:

```
[debug] Loading plugin {plugin-name}
```
{:.no-copy-code}

## Remove a plugin

There are three steps to completely remove a plugin.

1. Remove the plugin from any {{site.base_gateway}} entity that uses it. 
   Make sure that it is no longer applied globally nor for any Gateway Service, Route, or Consumer. 
   This has to be done only once for the entire {{site.base_gateway}} cluster, no restart or reload required.  
   This step in itself will ensure that the plugin is no longer in use, but it remains available and it's still possible to re-apply the plugin.

1. Remove the plugin from the `plugins` directive on each {{site.base_gateway}} node.
   Make sure to have completed the first step before doing so. 
   After this step it will be impossible to re-apply the plugin. 
   This step requires to restart or reload the {{site.base_gateway}} node.

1. To remove the plugin thoroughly, delete the plugin-related files from each of the {{site.base_gateway}} nodes. 
   Before deleting the files, make sure to have completed the previous step, including restarting or reloading {{site.base_gateway}}. 
   If you used LuaRocks to install the plugin, you can do `luarocks remove {plugin-name}` to remove it.



## Distribute your plugin

Depending on the platform that {{site.base_gateway}} is running on, there are different ways of distributing custom plugins.

### LuaRocks

You can use [LuaRocks](https://luarocks.org/), a package manager for Lua modules. 
Your module doesn't have to live inside the {{site.base_gateway}} repository, but it can if that's how you'd like to maintain your {{site.base_gateway}} setup.

By defining your modules (and their eventual dependencies) in a [rockspec](https://github.com/keplerproject/luarocks/wiki/Creating-a-rock) file, you can install those modules on your platform via LuaRocks. 
You can also upload your module on LuaRocks and make it available to anyone.

Here is an [example rockspec](https://github.com/Kong/kong-plugin/blob/master/kong-plugin-myplugin-0.1.0-1.rockspec) using the `builtin` build type to define modules in Lua notation and their corresponding file.

For more information about the format, see the LuaRocks [documentation on rockspecs](https://github.com/keplerproject/luarocks/wiki/Creating-a-rock).

### OCI Artifacts

{{site.base_gateway}} plugins can be packaged as generic OCI artifacts and uploaded to an OCI-compliant registry like Docker Hub or Amazon ECR for versioning, storage, and distribution. 

The advantage of distributing plugins as OCI artifacts is that users can make use of a number of ecosystem benefits including tooling around building, pushing and pulling, and signing (for secure provenance attestation) of these artifacts. 
The steps below illustrate a sample flow for packaging, distributing, and verifying a {{site.base_gateway}} custom plugin as an OCI artifact.

On the machine where the plugin is developed, run the following steps:

1. Package the plugin:
   ```bash
   tar czf my-plugin.tar.gz ./my-plugin-dir
   ```

1. Use the [Cosign tool](https://docs.sigstore.dev/system_config/installation/) to generate a key pair for use signing and verifying plugins:
   ```bash
   cosign generate-key-pair
   ```
   The private key, `cosign.key`, should be kept secure and is used for signing the plugin artifact. 
   The public key, `cosign.pub`, should be distributed and used by target machines to validate the downloaded plugin later in the flow. 

   There are also key-less methods for signing and verifying artifacts with Cosign. 
   More information is available in their [documentation](https://docs.sigstore.dev/signing/overview/).

1. Login to your OCI-compliant registry. In this case we'll use Docker Hub:
   ```bash
   cat ~/foo_password.txt | docker login --username foo-user --password-stdin
   ```

1. Upload the plugin artifact to the OCI registry using Cosign. 
   This is the equivalent of running  `docker push {image}` when pushing a local Docker image up to a registry.
   ```bash
   cosign upload blob -f my-plugin.tar.gz docker.io/foo-user/my-plugin
   ```
   The `cosign upload` command will return the digest of the artifact if it's successfully uploaded.

1. Sign the artifact with the key pair generated in step 1:
   ```bash
   cosign sign --key cosign.key index.docker.io/foo-user/my-plugin@sha256:xxxxxxxxxx
   ```

   The command may prompt for the private key passphrase. 
   It also may prompt to confirm that you consent to the signing information being permanently recorded in Rekor, the transparency log. 
   For more information on Sigstore tooling and flows visit the [documentation](https://docs.sigstore.dev/logging/overview/).

Then, on the {{site.base_gateway}} Data Plane nodes, run the following steps:

1. Ensure the `cosign.pub` public key is available. 
   Verify the signature of the plugin artifact that you want to pull:
   ```bash
   cosign verify --key cosign.pub index.docker.io/foo-user/my-plugin@sha256:xxxxxxxxxx
   ```

   The command should succeed if the artifact was verified.

1. Use the [Crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane) tool to pull the plugin artifact to the machine:
   ```bash
   crane pull index.docker.io/foo-user/my-plugin@sha256:xxxxxxxxxx my-downloaded-plugin.tar.gz
   ```
   The command should pull the artifact and save it to the working directory.

1. Unpackage the plugin. 
   The downloaded `.tar.gz` file will contain a manifest file and another nested `.tar.gz`. 
   This nested archive contains the plugin directory.

   ```bash
   tar xvf my-downloaded-plugin.tar.gz
   tar xvf xxxxxxxxxxxxxxxxxxxxx.tar.gz
   ```

1. Copy the plugin directory to the correct location following the [install manually](#manually) section. 
   If you have not set a custom `KONG_LUA_PACKAGE_PATH`, copy the plugin to `/usr/local/share/lua/5.1/kong/plugins`.

1. Update {{site.base_gateway}}'s configuration to load the custom plugin by configuring `plugins=bundled,my-downloaded-plugin` in `kong.conf` or set the `KONG_PLUGINS` environment variable to `plugins=bundled,my-downloaded-plugin`

## Troubleshooting

{{site.base_gateway}} can fail to start because of a misconfigured custom plugin for several reasons:

{% table %}
columns:
  - title: Error
    key: error
  - title: Cause
    key: cause
  - title: Solution
    key: solution
rows:
  - error: "`plugin is in use but not enabled`"
    cause: |
      You configured a custom plugin from another node and that the plugin configuration is in the database, but the current node you are trying to start does not have it in its `plugins` directive.
    solution: |
      Add the plugin's name to the node's `plugins` directive.
  - error: "`plugin is enabled but not installed`"
    cause: |
      The plugin's name is present in the `plugins` directive, but {{site.base_gateway}} can't load the `handler.lua` source file from the file system.
    solution: |
      Make sure that the [`lua_package_path`](/gateway/configuration/#lua-package-path) directive is properly set to load this plugin's Lua sources.
  - error: "`no configuration schema found for plugin`"
    cause: |
      The plugin is installed and enabled in the `plugins` directive, but {{site.base_gateway}} is unable to load the `schema.lua` source file from the file system.
    solution: |
      Make sure that the `schema.lua` file is present alongside the plugin's `handler.lua` file.
{% endtable %}