---
title: decK file
short_title: Overview
description: Manipulate a decK configuration file programmatically. Layer in additional configuration and lint against your governance rules
weight: 1000

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/

related_resources:
  - text: All decK documentation
    url: /index/deck/
---

decK's declarative configuration format is the canonical representation of a {{ site.base_gateway }} configuration in text form.

decK provides multiple tools for interacting with this declarative configuration.

| Command                                  | Description                                                                                                                                                                     |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [openapi2kong](/deck/file/openapi2kong/) | Convert an OpenAPI specification to {{ site.base_gateway }} Services and Routes.                                                                                                                   |
| [kong2kic](/deck/file/kong2kic/)         | Convert a Kong declarative configuration file to [{{site.kic_product_name}}](/kubernetes-ingress-controller/) compatible CRDs. Supports both Gateway API and Ingress resources. |
| [kong2tf](/deck/file/kong2tf/)           | Convert a Kong declarative configuration file to Terraform manifests (Konnect only).                                                                                            |

decK also provides commands to manipulate declarative configuration files:

| Command                                         | Description                                                                 |
| ----------------------------------------------- | --------------------------------------------------------------------------- |
| [patch](/deck/file/manipulation/patch/)         | Update values in a Kong declarative configuration file.                     |
| [add-plugins](/deck/file/manipulation/plugins/) | Add new Plugin configurations to a Kong declarative configuration file.     |
| [add-tags](/deck/file/manipulation/tags/)       | Add new tags to a Kong declarative configuration file.                      |
| [list-tags](/deck/file/manipulation/tags/)      | List all tags in a Kong declarative configuration file.                     |
| [remove-tags](/deck/file/manipulation/tags/)    | Remove tags to a Kong declarative configuration file.                       |
| [merge](/deck/file/merge/)                      | Merge multiple files in to a single file, leaving `env` variables in place. |
| [render](/deck/file/render/)                    | Render the final configuration sent to the Admin API in a single file.      |
| [namespace](/deck/file/manipulation/namespace/) | Apply a namespace to Routes in a decK file by path or hostname.             |
| [convert](/deck/file/convert/)                  | Convert decK files from one format to another, for example Kong 2.x to 3.x. |

decK provides a `deck file lint` command which can be used to ensure that declarative configuration files meet defined standards before being used to configure {{ site.base_gateway }}.

Finally, the `deck file validate` command validates the state file locally against static schemas. This won't detect any conflicts on the server, but is much faster than `deck gateway validate`.
