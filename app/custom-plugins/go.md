---
title: Writing plugins in Go
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/

products:
    - gateway

works_on:
    - on-prem

description: Learn how to write plugins for {{site.base_gateway}} in Go.

tags:
  - custom-plugins

min_version:
  gateway: '3.4'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: Writing plugins in Javascript
    url: /custom-plugins/javascript/
  - text: Writing plugins in Python
    url: /custom-plugins/python/
  - text: Running plugins in containers
    url: /custom-plugins/installation-and-distribution/#via-a-dockerfile-or-docker-run-install-and-load
  - text: Go PDK repository
    url: https://github.com/Kong/go-pdk
---

{{site.base_gateway}} supports Go plugin development through the [Go PDK](https://pkg.go.dev/github.com/Kong/go-pdk) library,
which provides Go bindings for {{site.base_gateway}}.

## Development

To write a {{site.base_gateway}} plugin in Go, you need to:

1. Define a `structure` type to hold configuration.
2. Write a `New()` function to create instances of your structure.
3. Add methods to that structure to handle phases.
4. Include the `go-pdk/server` sub-library.
5. Add a `main()` function that calls `server.StartServer(New, Version, Priority)`.
6. Compile as an executable with `go build`.

See the [Go PDK repository](https://github.com/Kong/go-pdk/tree/master/examples) for examples of plugins built with Go.

## Configuration

Configuration reference for the Go PDK.

<!--vale off-->
### Struct
<!--vale on-->

The plugin you write needs a way to handle incoming configuration data from the data store or the Admin API.
You can use a `struct` to create a schema of the incoming data.

```go
type MyConfig struct {
    Path   string
    Reopen bool
}
```
Because this plugin will be processing configuration data, you are going to want to control encoding using the `encoding/json` package.
Go fields that start with a capital letter can be exported, making them accessible outside of the current package, including by the `encoding/json` package.
If you want the fields to have a different name in the data store, add tags to the fields in your `struct`.

```go
type MyConfig struct {
    Path   string `json:"my_file_path"`
    Reopen bool   `json:"reopen"`
}
```

<!--vale off-->
### New() constructor
<!--vale on-->

The plugin must define a function called `New`.
This function should instantiate the `MyConfig` struct and return it as an `interface`.

```go
func New() interface{} {
    return &MyConfig{}
}
```

<!--vale off-->
### main() function
<!--vale on-->

Each plugin is compiled as a standalone executable. 
Include `github.com/Kong/go-pdk` in the imports list, and add a `main()` function:

```go
func main () {
  server.StartServer(New, Version, Priority)
}
```

Executables can be placed somewhere in your path (for example, `/usr/local/bin`). 
For example, the `-h` flag shows a usage help message:

```sh
my-plugin -h
```

Output:
```sh
Usage of my-plugin:
  -dump
        Dump info about plugins
  -help
        Show usage info
  -kong-prefix string
        Kong prefix path (specified by the -p argument commonly used in the Kong CLI) (default "/usr/local/kong")
```
{:.no-copy-code}

When you run the plugin without arguments, it creates a socket file within the `kong-prefix` and the executable name, appending `.socket`.
For example, if the executable is `my-plugin`, the socket file would be `/usr/local/kong/my-plugin.socket`.

### Phase handlers

In {{site.base_gateway}} Lua plugins, you can implement custom logic to be executed at various [phases](/custom-plugins/handler.lua/) of the request processing lifecycle. 
For example, to execute custom Go code during the access phase, create a function named `Access` with the following function signature:

```go
func (conf *MyConfig) Access (kong *pdk.PDK) {
  ...
}
```

You can implement custom logic during the following phases using the same function signature:

* `certificate`
* `rewrite`
* `access`
* `response`
* `preread`
* `log`

The presence of the `Response` handler automatically enables the buffered proxy mode.

### Version and priority

You can define the version number and priority of execution by declaring the following constants within the plugin code:

```go
const Version = "1.0.0"
const Priority = 1
```

{{site.base_gateway}} executes plugins from highest priority to lowest.

## Loading the plugin into {{site.base_gateway}}

To load plugins using the `kong.conf` [configuration file](/gateway/configuration/), you have to map existing {{site.base_gateway}} properties to aspects of your plugin.
Here are two examples of loading plugins within `kong.conf`:

```
pluginserver_names = my-plugin,other-one

pluginserver_my_plugin_socket = /usr/local/kong/my-plugin.socket
pluginserver_my_plugin_start_cmd = /usr/local/bin/my-plugin
pluginserver_my_plugin_query_cmd = /usr/local/bin/my-plugin -dump

pluginserver_other_one_socket = /usr/local/kong/other-one.socket
pluginserver_other_one_start_cmd = /usr/local/bin/other-one
pluginserver_other_one_query_cmd = /usr/local/bin/other-one -dump

plugins = bundled,my-plugin,other-one
```

The socket and start command settings coincide with
their defaults and can be omitted:

```
pluginserver_names = my-plugin,other-one
pluginserver_my_plugin_query_cmd = /usr/local/bin/my-plugin -dump
pluginserver_other_one_query_cmd = /usr/local/bin/other-one -dump
plugins = bundled,my-plugin,other-one
```
