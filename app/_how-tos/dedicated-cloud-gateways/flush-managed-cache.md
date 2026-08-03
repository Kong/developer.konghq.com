---
title: Flush a Dedicated Cloud Gateway managed cache using Terraform
description: 'Use Terraform to deploy a custom plugin that flushes a Dedicated Cloud Gateway AWS managed cache on demand.'
content_type: how_to
permalink: /dedicated-cloud-gateways/flush-managed-cache/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
tools:
  - terraform
min_version:
  gateway: '3.13'
tags:
  - dedicated-cloud-gateways
  - terraform
  - aws
  - caching
  - custom-plugins
automated_tests: false
tldr:
  q: How do I flush a Dedicated Cloud Gateway AWS managed cache using Terraform?
  a: |
    Deploy a `konnect_gateway_custom_plugin_streaming` custom plugin that authenticates to the managed cache via AWS STS and runs `FLUSHDB`, exposed through a `konnect_gateway_service` and `konnect_gateway_route`, then trigger a flush by calling the Terraform output URL.
related_resources:
  - text: Managed cache for Redis
    url: /dedicated-cloud-gateways/managed-cache/
  - text: Configure an AWS managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/aws-managed-cache-control-plane/
prereqs:
  show_works_on: false
  inline:
    - title: Terraform and the Konnect provider
      include_content: prereqs/products/konnect-terraform
      icon_url: /assets/icons/terraform.svg
    - title: An AWS managed cache
      include_content: prereqs/dcgw-aws-managed-cache
      icon_url: /assets/icons/kogo-white.svg
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

An AWS [managed cache](/dedicated-cloud-gateways/managed-cache/) doesn't expose a built-in way to clear its contents on demand.
This how-to deploys a custom Kong plugin that exposes a flush endpoint on your gateway.
Calling the endpoint authenticates to the managed cache with AWS STS-derived credentials and runs `FLUSHDB`, so you (or your CI/CD pipeline) can flush the cache without engineering involvement.

## Upload the custom plugin

1. Create a `schema.lua` file that defines the plugin's configuration fields.

    {% details %}
    summary: "Expand to see the schema.lua command"
    content: |
      <!--vale off-->
      ```bash
      echo '
      local typedefs = require "kong.db.schema.typedefs"

      return {
        name = "cache-flusher",
        fields = {
          { protocols = typedefs.protocols_http },
          {
            config = {
              type = "record",
              fields = {
              { host = typedefs.host({ default = "127.0.0.1", referenceable = true }) },
              { port = typedefs.port({ default = 6379, referenceable = true }) },
              { username = { type = "string", referenceable = true } },
              { ssl = { type = "boolean", default = true } },
              { server_name = { type = "string", referenceable = true } },
              { cloud_authentication = {
                  type = "record",
                  fields = {
                    { auth_provider = { type = "string", referenceable = true } },
                    { aws_region = { type = "string", referenceable = true } },
                    { aws_assume_role_arn = { type = "string", referenceable = true } },
                    { aws_cache_name = { type = "string", referenceable = true } },
                  }
              }},
            }
            },
          },
        },
      }
      ' > schema.lua
      ```
      <!--vale on-->
    {% enddetails %}

1. Create a `handler.lua` file that authenticates to the managed cache and runs the flush.

    {% details %}
    summary: "Expand to see the handler.lua command"
    content: |
      <!--vale off-->
      ```bash
      echo '
      local AWS = require "resty.aws"
      local redis = require "resty.redis"
      local aws_config = require "resty.aws.config"

      local AWS_DEFAULT_ROLE_SESSION_NAME = "KongElasticacheSession"
      local AWS_global_config = aws_config.global
      local aws = AWS({ region = AWS_global_config.region })

      local plugin = {
        PRIORITY = 1000,
        VERSION  = "1.0.0",
      }

      local function get_aws_auth_token(conf, cloud_auth)
          local cachename = cloud_auth.aws_cache_name
          local name = conf.username
          local region = cloud_auth.aws_region
          local assume_role_arn = cloud_auth.aws_assume_role_arn

          local credentials = aws.config.credentials

          local sts, err = aws:STS({
              region = region,
              credentials = credentials,
              stsRegionalEndpoints = AWS_global_config.sts_regional_endpoints,
          })
          if not sts then
              return nil, err
          end

          local creds = aws:ChainableTemporaryCredentials {
              params = {
                  RoleArn = assume_role_arn,
                  RoleSessionName = AWS_DEFAULT_ROLE_SESSION_NAME,
              },
              sts = sts,
          }

          local cache = aws:ElastiCache({ region = region })

          local signer = cache:Signer {
              cachename = cachename,
              username = name,
              is_serverless = false,
              region = region,
              credentials = creds,
          }

          local auth_token, token_err = signer:getAuthToken()
          if token_err then
              return nil, token_err
          end

          return auth_token
      end

      local function get_auth_token(conf)
          local cloud_auth = conf.cloud_authentication
          local provider = cloud_auth.auth_provider

          if provider == "aws" then
              return get_aws_auth_token(conf, cloud_auth)
          end

          return nil, "cloud provider '" .. tostring(provider) .. "' not implemented"
      end

      function plugin:access(conf)
          kong.log.notice("[cache-flusher] starting cache flush")

          -- Connect to Cache
          kong.log.notice("[cache-flusher] connecting to Cache at ", conf.host, ":", conf.port)

          local red = redis:new()
          local ok, err = red:connect(conf.host, conf.port, {
              ssl = conf.ssl,
              ssl_verify = conf.ssl,
              server_name = conf.server_name,
          })
          if not ok then
              kong.log.err("[cache-flusher] failed to connect to Cache: ", err)
              return kong.response.error(500, "cache flush failed: Cache connect error")
          end

          kong.log.notice("[cache-flusher] connected to Cache, obtaining auth token")

          -- Authenticate with STS-derived token
          local auth_token, token_err = get_auth_token(conf)
          if not auth_token then
              kong.log.err("[cache-flusher] failed to obtain auth token: ", token_err)
              return kong.response.error(500, "cache flush failed: auth token error")
          end

          kong.log.notice("[cache-flusher] auth token obtained, authenticating with Cache")

          local res, auth_err = red:auth(conf.username, auth_token)
          if not res then
              kong.log.err("[cache-flusher] failed to authenticate with Cache: ", auth_err)
              return kong.response.error(500, "cache flush failed: Cache auth error")
          end

          kong.log.notice("[cache-flusher] authenticated, flushing Cache")

          -- Flush Cache
          local flush_res, flush_err = red:flushdb("ASYNC")
          if not flush_res then
              kong.log.err("[cache-flusher] failed to flush Cache: ", flush_err)
              return kong.response.error(500, "cache flush failed: Cache flushdb error")
          end

          kong.log.notice("[cache-flusher] cache flush completed successfully")

          return kong.response.exit(200, { message = "[cache-flusher] cache flushed" })
      end

      return plugin
      ' > handler.lua
      ```
      <!--vale on-->
    {% enddetails %}

1. Declare the variables this how-to uses, and export the ones only you know:

    <!--vale off-->
    ```hcl
    echo '
    variable "control_plane_id" {
      type = string
    }

    variable "flush_path" {
      type    = string
      default = "/konnect/managed-cache/flush"
    }

    variable "ip_allowlist" {
      type    = list(string)
      default = []
    }

    variable "auto_flush" {
      type    = bool
      default = false
    }
    ' > variables.tf
    ```
    <!--vale on-->

    ```bash
    export TF_VAR_control_plane_id="your-control-plane-id"
    ```

1. Define the custom plugin, the service and route that expose the flush endpoint, and the plugin instance:

    <!--vale off-->
    ```hcl
    echo '
    resource "konnect_gateway_custom_plugin_streaming" "cache_flusher" {
      control_plane_id = var.control_plane_id
      name             = "cache-flusher"
      schema           = file("${path.module}/schema.lua")
      handler          = file("${path.module}/handler.lua")
    }

    resource "konnect_gateway_service" "cache_flusher_service" {
      control_plane_id = var.control_plane_id
      name             = "managed-cache-flush-service"
      host             = "127.0.0.1"
      port             = 443
      protocol         = "https"
    }

    resource "konnect_gateway_route" "cache_flusher_route" {
      control_plane_id = var.control_plane_id
      service = {
        id = konnect_gateway_service.cache_flusher_service.id
      }
      paths = [var.flush_path]
    }

    resource "konnect_gateway_custom_plugin" "cache_flusher_instance" {
      name             = "cache-flusher"
      control_plane_id = var.control_plane_id
      enabled          = true
      service = {
        id = konnect_gateway_service.cache_flusher_service.id
      }
      route = {
        id = konnect_gateway_route.cache_flusher_route.id
      }
      config = {
        "cloud_authentication" : {
          "auth_provider" : "{vault://env/ADDON_MANAGED_CACHE_AUTH_PROVIDER}",
          "aws_assume_role_arn" : "{vault://env/ADDON_MANAGED_CACHE_AWS_ASSUME_ROLE_ARN}",
          "aws_cache_name" : "{vault://env/ADDON_MANAGED_CACHE_AWS_CACHE_NAME}",
          "aws_region" : "{vault://env/ADDON_MANAGED_CACHE_AWS_REGION}"
        },
        "host" : "{vault://env/ADDON_MANAGED_CACHE_HOST}",
        "port" : "{vault://env/ADDON_MANAGED_CACHE_PORT}",
        "server_name" : "{vault://env/ADDON_MANAGED_CACHE_SERVER_NAME}",
        "ssl" : true,
        "username" : "{vault://env/ADDON_MANAGED_CACHE_USERNAME}"
      }

      depends_on = [konnect_gateway_custom_plugin_streaming.cache_flusher]
    }
    ' >> main.tf
    ```
    <!--vale on-->

    The `{vault://env/ADDON_MANAGED_CACHE_*}` references are populated automatically by {{site.konnect_short_name}} once your managed cache add-on reaches a Ready state, so you don't need to configure any AWS IAM credentials yourself.

1. Add an output for the flush URL:

    <!--vale off-->
    ```hcl
    echo '
    output "flush_proxy_url" {
      value = "${local.proxy_url}${var.flush_path}"
    }
    ' > output.tf
    ```
    <!--vale on-->

    <!--vale off-->
    ```hcl
    echo '
    data "konnect_gateway_control_plane" "control-plane" {
      filter = {
        id = {
          eq = var.control_plane_id
        }
      }
    }

    locals {
      cp_endpoint = data.konnect_gateway_control_plane.control-plane.config.control_plane_endpoint
      cp_short_id = regex("https://([^.]+)\\.", local.cp_endpoint)[0]
      proxy_url   = "https://${local.cp_short_id}.gateways.konggateway.com"
    }
    ' > data.tf
    ```
    <!--vale on-->

1. Apply the configuration:

    ```bash
    terraform apply -auto-approve
    ```

    ```text
    Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
    ```
    {:.no-copy-code}

### Optional: restrict access and auto-flush on apply

If you want to limit which IPs can trigger a flush, set `ip_allowlist` to a list of IPs or CIDRs, and add an `ip-restriction` plugin scoped to the flush route:

<!--vale off-->
```hcl
echo '
resource "konnect_gateway_plugin_ip_restriction" "ip-restriction-plugin" {
  count = length(var.ip_allowlist) > 0 ? 1 : 0

  config = {
    allow = var.ip_allowlist

    message = "NOT ALLOWED"
    status  = 405
  }

  control_plane_id = var.control_plane_id
  enabled          = true
  service = {
    id = konnect_gateway_service.cache_flusher_service.id
  }
  route = {
    id = konnect_gateway_route.cache_flusher_route.id
  }
}
' >> main.tf
```
<!--vale on-->

Requests from IPs outside the allowlist receive a `405` response.

If you want the cache to flush automatically every time you run `terraform apply`, set `auto_flush` to `true`:

<!--vale off-->
```hcl
echo '
resource "terraform_data" "flush_cache" {
  count = var.auto_flush ? 1 : 0

  triggers_replace = [timestamp()]

  provisioner "local-exec" {
    command = "sleep 10 && curl -sf ${local.proxy_url}${var.flush_path}"
  }

  depends_on = [
    konnect_gateway_route.cache_flusher_route,
    konnect_gateway_custom_plugin.cache_flusher_instance,
    konnect_gateway_plugin_ip_restriction.ip-restriction-plugin,
  ]
}
' >> main.tf
```
<!--vale on-->

{:.warning}
> When `auto_flush` is `true`, every `terraform apply` triggers a cache flush, not just the first one.
> Subsequent applies also show the `terraform_data.flush_cache` resource being destroyed and recreated.
> This is expected and can be safely ignored.

## Validate

Trigger a flush by calling the URL Terraform output in the previous step:

```bash
curl -sf "$(terraform output -raw flush_proxy_url)"
```

A successful flush returns:

```json
{"message": "[cache-flusher] cache flushed"}
```
{:.no-copy-code}

## Teardown

To remove the flush endpoint and all associated resources:

```bash
terraform destroy
```
