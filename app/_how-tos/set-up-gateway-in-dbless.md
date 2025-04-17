---
title: Set up {{site.base_gateway}} in DB-less mode
content_type: how_to
related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/

products:
    - gateway

works_on:
    - on-prem

min_version:
  gateway: '3.4'

entities: 
  - vault

tags:
    - logging

tldr:
    q: How do I 
    a: placeholder

tools:
    - deck


cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

@todo

pull content from https://docs.konghq.com/gateway/latest/production/deployment-topologies/db-less-and-declarative-config/

I'm adding some of the relevant content below, will need to be revised and tested


<!---content to use starts now-->

## Set up {{site.base_gateway}} in DB-less mode

To use {{site.base_gateway}} in DB-less mode, set the [`database` directive of `kong.conf`](/gateway/configuration/#database) to `off`. As usual, you can do this by editing `kong.conf` and setting
`database=off` or via environment variables. You can then start {{site.base_gateway}}
as usual:

```
export KONG_DATABASE=off
kong start -c kong.conf
```

Once {{site.base_gateway}} starts, access the `/` endpoint of the Admin API to verify that it
is running without a database:

```sh
curl -i -X GET http://localhost:8001
```

It will return the entire {{site.base_gateway}} configuration. Verify that `database` is set to `off` in the response body.

{{site.base_gateway}} is running, but no declarative configuration has been loaded yet. This
means that the configuration of this node is empty. There are no routes,
services, or entities of any kind.

## Create a declarative configuration file

To load entities into DB-less {{site.base_gateway}}, you need a declarative configuration
file. The following command creates a skeleton file to get you
started:

```
kong config -c kong.conf init
```

This command creates a `kong.yml` file in the current directory,
containing examples of the syntax for declaring entities and their
relationships. All examples in the generated file are commented-out
by default. You can experiment by uncommenting the examples
(removing the `#` markers) and modifying their values.

### Declarative configuration format

<!--I think we can do this in how to format if we do both a nested and not nested value, and then explain how the nesting and format works-->

The {{site.base_gateway}} declarative configuration format consists of lists of
[entities](/gateway/entities/) and their attributes. This is a small yet complete
example that illustrates a number of features:

```yaml
_format_version: "3.0"
_transform: true

services:
- name: my-service
  url: https://example.com
  plugins:
  - name: key-auth
  routes:
  - name: my-route
    paths:
    - /

consumers:
- username: my-user
  keyauth_credentials:
  - key: my-key
```

See the [declarative configuration schema](https://github.com/Kong/go-database-reconciler/blob/main/pkg/file/kong_json_schema.json)
for all configuration options.

The only mandatory piece of metadata is `_format_version: "3.0"`, which
specifies the version number of the declarative configuration syntax format.
This also matches the minimum version of {{site.base_gateway}} required to parse the file.

The `_transform` metadata is an optional boolean (defaults to `true`), which
controls whether schema transformations will occur while importing. The rule
of thumb for using this field is: if you are importing plain-text credentials
(i.e. passwords), you likely want to set it to `true`, so that {{site.base_gateway}} will
encrypt/hash them before storing them in the database. If you are importing
**already hashed/encrypted** credentials, set `_transform` to `false` so that
the encryption doesn't happen twice.

At the top level, you can specify any [{{site.base_gateway}} entity](/gateway/entities/), such as core entity like `services` and `consumers` or custom entities created
by plugins, like `keyauth_credentials`. This makes the declarative
configuration format inherently extensible, and it is the reason why `kong
config` commands that process declarative configuration require `kong.conf` to
be available, so that the `plugins` directive is taken into account.

When entities have a relationship, such as a Route that points to a Gateway Service,
this relationship can be specified via nesting.

Only one-to-one relationships can be specified by nesting. Relationships involving more than two entities, such as a
plugin that is applied to both a Service and a Consumer, must be done via a
top-level entry. In that case, the entities can be identified by their primary keys
or identifying names (the same identifiers that can be used to refer to them
in the Admin API). This is an example of a plugin applied to a Service and
a Consumer:

```yml
plugins:
- name: syslog
  consumer: my-user
  service: my-service
```

### Check the file

Once you are done editing the file, you can check the syntax
for any errors before attempting to load it into {{site.base_gateway}}:

```
kong config -c kong.conf parse kong.yml
```

You should get `parse successful` as a response.

## Load the declarative configuration file

There are two ways to load a declarative configuration file into {{site.base_gateway}}: using
`kong.conf` or the Admin API.

To load a declarative configuration file at {{site.base_gateway}} start-up, use the
`declarative_config` directive in `kong.conf` (or, as usual to all `kong.conf`
entries, the equivalent `KONG_DECLARATIVE_CONFIG` environment variable):

```
export KONG_DATABASE=off \
export KONG_DECLARATIVE_CONFIG=kong.yml \
kong start -c kong.conf
```

You can also load a declarative configuration file into a running
{{site.base_gateway}} node with the Admin API, using the `/config` endpoint. The
following example loads `kong.yml`:

```sh
curl -i -X POST http://localhost:8001/config \
  --form config=@kong.yml
```

{:.warning}
> The `/config` endpoint replaces the entire set of entities in memory
with the ones specified in the given file.

Another way you can start {{site.base_gateway}} in DB-less mode is by including the entire
declarative configuration in a string using the `KONG_DECLARATIVE_CONFIG_STRING`
environment variable:

```
export KONG_DATABASE=off
export KONG_DECLARATIVE_CONFIG_STRING='{"_format_version":"1.1", "services":[{"host":"httpbin.konghq.com","port":443,"protocol":"https", "routes":[{"paths":["/"]}]}],"plugins":[{"name":"rate-limiting", "config":{"policy":"local","limit_by":"ip","minute":3}}]}'
kong start
```