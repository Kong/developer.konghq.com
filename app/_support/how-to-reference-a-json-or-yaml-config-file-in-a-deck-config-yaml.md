---
title: How to reference a JSON or YAML config file in a deck config YAML
content_type: support
description: As it stands, decK does not offer the ability to reference JSON or YAML files from the filesystem in its config.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the decK feature of passing env variables in the config
    url: /deck/reference/env-variables/
tldr:
  q: How do I reference an external JSON or YAML file in a decK config file?
  a: |
    decK does not support referencing external JSON or YAML files directly from its config. As a workaround, load the file's contents into an environment variable (for example `export VAR=$(cat file.json)`) and reference it in the plugin config with decK's environment variable substitution, `{% raw %}${{ env "VAR" }}{% endraw %}`. This workaround is limited by your operating system's environment variable size limit.
---

## Overview

There are cases where it would be beneficial to be able to reference a piece of JSON or yaml via a parameter in a deck yaml file, rather than having to copy and paste it directly into the deck config, e.g. when defining the `api_spec` for the OAS validation plugin. Does decK support this requirement?

## Steps

As it stands, decK does not offer the ability to reference JSON or YAML files from the filesystem in its config.

However, a workaround that can work with some limitations, is to use the decK feature of passing env variables in the config.

Here's an example to show how to implement the solution.

We can save the json api-spec in a file called `swagger-petstore.json`

Then it can be loaded in an env variable like so:

`export DECK_OAS_SPEC_PETSTORE=$(cat swagger-petstore.json)`

The deck yaml would look like so:

```yaml

_format_version: "3.0"
services:
- connect_timeout: 60000
enabled: true
host: petstore.swagger.io
name: Petstore-Service
path: /v2
plugins:
- config:
allowed_header_parameters: Host,Content-Type,User-Agent,Accept,Content-Length
api_spec: {% raw %}${{ env "DECK_OAS_SPEC_PETSTORE" }}{% endraw %}
header_parameter_check: false
notify_only_request_validation_failure: false
notify_only_response_body_validation_failure: false
query_parameter_check: false
validate_request_body: true
validate_request_header_params: true
validate_request_query_params: true
validate_request_uri_params: true
validate_response_body: false
verbose_response: true
enabled: true
name: oas-validation
protocols:
- grpc
- grpcs
- http
- https
port: 443
protocol: https
read_timeout: 60000
retries: 5
routes:
- https_redirect_status_code: 426
name: Petstore-Route
path_handling: v0
paths:
- /.*
preserve_host: false
protocols:
- http
- https
regex_priority: 0
request_buffering: true
response_buffering: true
strip_path: true
write_timeout: 60000
```

Please note that the API specification can be either a JSON or YAML based file. If using a YAML file, the spec needs to be URL encoded to preserve the YAML format. However the process of passing it via an env var would be the same as above.

The limitation of this workaround depends on the size of the JSON or YAML file, since most operating systems would have a hard limit on the size of a environment variable. That means that this workaround will not work for files greater than the env var size limit.
