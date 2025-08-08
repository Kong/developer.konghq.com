---
title: Writing plugins in JavaScript
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn how to write plugins for {{site.base_gateway}} in JavaScript.

tags:
  - custom-plugins

min_version:
  gateway: '3.4'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: Writing plugins in Go
    url: /custom-plugins/go/
  - text: Writing plugins in Python
    url: /custom-plugins/python/
  - text: Running plugins in containers
    url: /custom-plugins/installation-and-distribution/#via-a-dockerfile-or-docker-run-install-and-load
  - text: JavaScript PDK repository
    url: https://github.com/Kong/kong-js-pdk
---

{{site.base_gateway}} supports JavaScript plugin development through the [JavaScript PDK](https://github.com/Kong/kong-js-pdk).
The `kong-js-pdk` library provides a plugin server that provides a runtime for JavaScript bindings for {{site.base_gateway}}.

TypeScript is also supported in the following ways:

* The PDK includes type definitions for PDK functions that allow type checking when developing plugins in TypeScript.
* Plugins written in TypeScript can be loaded directly to {{site.base_gateway}} and transpiled.

{:.info}
> **Using JavaScript plugins in Konnect**
>
> You can use JavaScript plugins on the data plane in Konnect. However, you must **provide the plugin schema in Lua format** to Konnect in order to configure the custom plugin.

## Installation

You can install the [JavaScript PDK](https://github.com/Kong/kong-js-pdk) using `npm`.
To install the plugin server binary globally, run the following command:

```sh
npm install kong-pdk -g
```

## Development

A valid JavaScript plugin implementation should export the following object:

```javascript
module.exports = {
  Plugin: KongPlugin,
  Schema: [
    { message: { type: "string" } },
  ],
  Version: '0.1.0',
  Priority: 0,
}
```

* The `Plugin` attribute defines the class that implements this plugin.
* The `Schema` defines the configuration schema of the plugin.
* `Version` and `Priority` variables set to the version number and priority of execution.

See the [JavaScript PDK repository](https://github.com/Kong/kong-js-pdk/tree/master/examples) for examples of plugins built with JavaScript.

## Configuration

Configuration reference for the JavaScript PDK.

### Phase handlers

You can implement custom logic to be executed at various [phases](/custom-plugins/handler.lua/) in the request processing lifecycle.
For example, to execute custom JavaScript code in the access phase, define a function named `access`:

```javascript
class KongPlugin {
  constructor(config) {
    this.config = config
  }
  async access(kong) {
    // ...
  }
}
```

You can implement custom logic during the following phases using the same function signature:

* `certificate`
* `rewrite`
* `access`
* `response`
* `preread`
* `log`

The presence of the `response` handler automatically enables the buffered proxy mode.

### PDK functions

Kong interacts with the PDK through network-based inter-rocess communication.
Each function returns a [promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) instance.

You can use `async` and `await` keywords in the phase handlers for better readability.
For example:

```javascript
class KongPlugin {
  constructor(config) {
    this.config = config
  }
  async access(kong) {
    let host = await kong.request.getHeader("host")
    // do something to host
  }
}
```

Alternatively, use the `then` method to resolve a promise:

```javascript
class KongPlugin {
  constructor(config) {
    this.config = config
  }
  async access(kong) {
    kong.request.getHeader("host")
      .then((host) => {
        // do something to host
      })
  }
}
```

### Plugin dependencies

When using the plugin server, plugins are allowed to have extra dependencies, as long as the
directory that holds plugin source code also includes a `node_modules` directory.

Assuming plugins are stored under `/usr/local/kong/js-plugins`, the extra dependencies are
then defined in `/usr/local/kong/js-plugins/package.json`.

Developers also need to run `npm install` under `/usr/local/kong/js-plugins` to install those dependencies locally
into `/usr/local/kong/js-plugins/node_modules`.

The Node.js version and architecture that runs the plugin server and
the one that runs `npm install` under plugins directory must match.

When running TypeScript plugins, `kong-pdk` needs to be defined as a dependency in `package.json`:

````json
{
  "name": "ts_hello",
  "version": "0.1.0",
  "description": "hello TS plugin from kong",
  "main": "ts_hello.ts",
  "dependencies": {
    "kong-pdk": "^0.5.5"
  }
}
````
Then, import `kong-pdk` in your TypeScript file:

````javascript
import kong from "kong-pdk/kong";
````

#### Testing

The JavaScript PDK provides a mock framework to test plugin code using [`jest`](https://jestjs.io/).

Install `jest` as a development dependency, then add  the `test` script in `package.json`:

```sh
npm install jest --save-dev
```

The `package.json` contains information like this:

```json
{
    "scripts": {
    "test": "jest"
    },
    "devDependencies": {
    "jest": "^26.6.3",
    "kong-pdk": "^0.3.2"
    }
}
```

Run the test through npm with:

```sh
npm test
```

See the [JavaScript PDK repo](https://github.com/Kong/kong-js-pdk/tree/master/examples) for examples of writing tests with `jest`.

## Loading the plugin into {{site.base_gateway}}

Prepare the system by installing the required dependencies.

For example, in Debian/Ubuntu based systems:

````sh
apt update
apt install -y nodejs npm
npm install -g kong-pdk
````

Copy the plugin code and the `package.json` file in `/usr/local/kong/js-plugins`, then run:

````sh
cd /usr/local/kong/js-plugins/
npm install
````

To load plugins using the `kong.conf` [configuration file](/gateway/configuration/), you have to map existing {{site.base_gateway}} properties to aspects of your plugin.

Here is an example of loading two plugins within `kong.conf`:

```
pluginserver_names = my-plugin,other-one

pluginserver_my_plugin_socket = /usr/local/kong/my-plugin_pluginserver.sock
pluginserver_my_plugin_start_cmd = /usr/bin/kong-js-pluginserver --plugins-directory /usr/local/kong/js-plugins/my-plugin --sock-name my-plugin_pluginserver.sock
pluginserver_my_plugin_query_cmd = /usr/bin/kong-js-pluginserver --plugins-directory /usr/local/kong/js-plugins/my-plugin --dump-all-plugins

pluginserver_other_one_socket = /usr/local/kong/other-one_pluginserver.sock
pluginserver_other_one_start_cmd = /usr/bin/kong-js-pluginserver --plugins-directory /usr/local/kong/js-plugins/other-one --sock-name other-one_pluginserver.sock
pluginserver_other_one_query_cmd = /usr/bin/kong-js-pluginserver --plugins-directory /usr/local/kong/js-plugins/other-one --dump-all-plugins

plugins = bundled,my-plugin,other-one
```

If you want to open verbose logging, pass the `-v` argument to the `start` command line:

```
pluginserver_my_plugin_start_cmd = /usr/bin/kong-js-pluginserver -v --plugins-directory /usr/local/kong/js-plugins/my-plugin --sock-name my-plugin_pluginserver.sock
```
