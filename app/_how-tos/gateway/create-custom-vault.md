---
title: Create a custom vault backend
permalink: /how-to/create-custom-vault/
content_type: how_to

description: Learn how to write a custom vault backend for {{site.base_gateway}} and use it to inject secrets into plugin configuration at request time.

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.4'

entities:
  - vault
  - service
  - route
  - plugin

plugins:
  - request-transformer-advanced

tags:
  - secrets-management
  - security

tldr:
  q: How do I create a custom vault backend in {{site.base_gateway}}?
  a: |
    Write a Lua module in `kong/vaults/<name>.lua` that exports `name`, `VERSION`, `init`, and `get`. Add a schema at `kong/vaults/<name>/schema.lua`. Start {{site.base_gateway}} with `KONG_VAULTS: bundled,<name>` and `KONG_LUA_PACKAGE_PATH` pointing to your code. Create a Vault entity, then reference secrets with `{vault://<prefix>/<key>}` in any referenceable field.

tools:
  - deck

prereqs:
  skip_product: true
  inline:
    - title: Docker and Docker Compose
      content: |
        Install [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/).
      icon_url: /assets/icons/gateway.svg
    - title: Export your Kong Gateway license
      content: |
        Export your {{site.ee_product_name}} license as an environment variable:
        ```bash
        export KONG_LICENSE_DATA='your-license-contents'
        ```
      icon_url: /assets/icons/gateway.svg

cleanup:
  inline:
    - title: Destroy the Docker Compose environment
      content: |
        Stop and remove all containers and volumes:
        ```bash
        docker compose down -v
        ```
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Vault entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret

next_steps:
  - text: Vault entity reference
    url: /gateway/entities/vault/
  - text: Secrets management overview
    url: /gateway/secrets-management/

faqs:
  - q: When is `get` called?
    a: |
      {{site.base_gateway}} calls `get` whenever it needs to resolve a `{vault://...}` reference. With the default TTL, the resolved value is cached and `get` is not called again until the TTL expires. Set `KONG_VAULT_<NAME>_TTL=0` to disable caching and call `get` on every request.
  - q: Can my vault return a value other than a string?
    a: |
      No. `get` must return a string or `nil`. {{site.base_gateway}} stores the resolved value as a string and injects it into the plugin config field as-is.
  - q: |
      {% include /gateway/vaults-format-faq.md type='question' %}
    a: |
      {% include /gateway/vaults-format-faq.md type='answer' %}

---

## Create the vault module

A custom vault backend is a Lua module with two required functions:

<!--vale off-->
{% table %}
columns:
  - title: Function
    key: function
  - title: Description
    key: description
rows:
  - function: "`init(conf)`"
    description: Called once at startup. Use it to validate config or open persistent connections.
  - function: "`get(conf, resource, version)`"
    description: "Called to resolve a secret reference. Returns the secret value as a string, or `nil` if not found. `resource` is the key portion of the `{vault://prefix/key}` reference."
{% endtable %}
<!--vale on-->

Create the directory structure:

```bash
mkdir -p kong/vaults/http
```

Create `kong/vaults/http.lua`:

```lua
echo '
local http = require("resty.http")
local cjson = require("cjson")

local function init(conf)
end

local function get(conf, resource, version)
  local base_url = conf.base_url or "http://localhost:9876/sekretz"

  local httpc = http.new()
  local res, err = httpc:request_uri(base_url .. "/" .. resource, {
    method = "GET",
    headers = {
      ["Accept"] = "application/json",
    },
  })

  if not res then
    ngx.log(ngx.WARN, "http vault: request failed for ", resource, ": ", err)
    return nil
  end

  if res.status ~= 200 then
    ngx.log(ngx.WARN, "http vault: status ", res.status, " for ", resource)
    return nil
  end

  local ok, data = pcall(cjson.decode, res.body)
  if not ok or data == nil then
    ngx.log(ngx.WARN, "http vault: failed to decode JSON for ", resource)
    return nil
  end

  return data.value
end

return {
  name = "http",
  VERSION = "1.0.0",
  init = init,
  get = get,
}' > kong/vaults/http.lua
```

The module fetches `<base_url>/<resource>` and returns the `value` field from the JSON response body.

## Create the vault schema

The schema declares the configuration fields exposed on the Vault entity. Create `kong/vaults/http/schema.lua`:

```lua
echo 'return {
  name = "http",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            base_url = {
              type = "string",
              default = "http://localhost:9876/sekretz",
              description = "Base URL of the HTTP secret store. Secrets are fetched from <base_url>/<key>.",
            },
          },
        },
      },
    },
  },
}' > kong/vaults/http/schema.lua
```

## Start Kong with the custom vault

Kong must be started with the custom vault registered. This requires setting `KONG_VAULTS` and mounting the Lua files into the container before {{site.base_gateway}} starts.

1. Create a secret that the vault will serve:

   ```bash
   mkdir -p secrets/sekretz
   echo '{"value":"X-From-Vault:top-secret-value"}' > secrets/sekretz/x-from-vault
   ```

2. Create `docker-compose.yml`:

   ```yaml
   echo '
   services:
     secret-store:
       image: busybox
       command: httpd -f -p 9876 -h /www
       volumes:
         - ./secrets:/www
       healthcheck:
         test: ["CMD", "wget", "-q", "-O", "/dev/null", "http://localhost:9876/sekretz/x-from-vault"]
         interval: 3s
         timeout: 5s
         retries: 10
         start_period: 5s

     postgres:
       image: postgres:16
       environment:
         POSTGRES_USER: kong
         POSTGRES_PASSWORD: kong
         POSTGRES_DB: kong
       healthcheck:
         test: ["CMD", "pg_isready", "-U", "kong"]
         interval: 5s
         timeout: 5s
         retries: 10
       restart: unless-stopped

     kong-migrations:
       image: kong/kong-gateway:latest
       command: kong migrations bootstrap
       environment:
         KONG_DATABASE: postgres
         KONG_PG_HOST: postgres
         KONG_PG_USER: kong
         KONG_PG_PASSWORD: kong
         KONG_PG_DATABASE: kong
         KONG_LICENSE_DATA: ${KONG_LICENSE_DATA}
       depends_on:
         postgres:
           condition: service_healthy

     kong:
       image: kong/kong-gateway:latest
       environment:
         KONG_DATABASE: postgres
         KONG_PG_HOST: postgres
         KONG_PG_USER: kong
         KONG_PG_PASSWORD: kong
         KONG_PG_DATABASE: kong
         KONG_LICENSE_DATA: ${KONG_LICENSE_DATA}
         KONG_PROXY_LISTEN: "0.0.0.0:8000"
         KONG_ADMIN_LISTEN: "0.0.0.0:8001"
         KONG_VAULTS: bundled,http
         KONG_LUA_PACKAGE_PATH: /custom-code/?.lua;;
       ports:
         - "8000:8000"
         - "8001:8001"
       volumes:
         - ./kong:/custom-code/kong
       depends_on:
         postgres:
           condition: service_healthy
         kong-migrations:
           condition: service_completed_successfully
         secret-store:
           condition: service_healthy
       healthcheck:
         test: ["CMD", "kong", "health"]
         interval: 10s
         timeout: 5s
         retries: 10
       restart: unless-stopped' > docker-compose.yml
   ```

   The two key environment variables for custom vaults are:
   - `KONG_VAULTS: bundled,http` — registers the built-in vaults plus the custom `http` vault
   - `KONG_LUA_PACKAGE_PATH: /custom-code/?.lua;;` — tells Kong where to find the Lua modules

3. Start all services:

   ```bash
   docker compose up -d
   ```

## Create the Vault entity

Create a Vault entity that configures the `http` vault backend. The `prefix` value (`http-vault`) is used in secret references:

{% entity_examples %}
entities:
  vaults:
    - name: http
      prefix: http-vault
      description: Custom HTTP vault backend
      config:
        base_url: http://secret-store:9876/sekretz
{% endentity_examples %}

The `base_url` uses the Docker Compose service name (`secret-store`) as the hostname, since Kong and the secret store run in the same Docker network.

## Configure the plugin with a vault reference

Create a service and route, then enable the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin. The `add.headers` list accepts items in `header-name:value` format. Here the vault reference is used as the entire item — Kong resolves `{vault://http-vault/x-from-vault}` to `X-From-Vault:top-secret-value`, which the plugin then parses into header name `X-From-Vault` and value `top-secret-value`.

{% entity_examples %}
entities:
  services:
    - name: httpbin
      url: http://httpbin.konghq.com/anything
      routes:
        - name: httpbin-route
          paths:
            - /
          protocols:
            - http
      plugins:
        - name: request-transformer-advanced
          config:
            add:
              headers:
                - "{vault://http-vault/x-from-vault}"
{% endentity_examples %}

## Validate

Send a request through the proxy:

<!--vale off-->
{% validation request-check %}
url: /
status_code: 200
{% endvalidation %}
<!--vale on-->

The [httpbin](https://httpbin.konghq.com) upstream echoes the full incoming request as a JSON response body. Check the `headers` object for `X-From-Vault`:

```json
{
  "headers": {
    "X-From-Vault": "top-secret-value"
  }
}
```
{:.no-copy-code}

If the header is present with the value from `secrets/sekretz/x-from-vault`, the custom vault is working correctly.
