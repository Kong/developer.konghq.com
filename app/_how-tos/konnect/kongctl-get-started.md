---
title: Get started with kongctl
description: "Learn how to use kongctl to manage {{site.konnect_product_name}} resources"
content_type: how_to
permalink: /kongctl/get-started/
beta: true
breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration guide
    url: /kongctl/declarative/

products:
  - konnect

works_on:
  - konnect

tags:
  - cli
  - get-started
  - declarative-config

tldr:
  q: How do I get started with kongctl?
  a: |
    This guide teaches you how to use kongctl to manage {{site.konnect_short_name}} resources.
    You'll authenticate, view resources, and use declarative configuration to manage infrastructure as code.

tools:
  - kongctl

automated_tests: false

prereqs:
  skip_product: false
  show_works_on: false
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial requires a {{site.konnect_short_name}} account. If you don't have an account, 
        you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).
      icon_url: /assets/icons/gateway.svg

next_steps:
  - text: Learn about kongctl authorization options
    url: /kongctl/authentication/
  - text: Manage {{site.konnect_short_name}} resources declaratively
    url: /kongctl/declarative/
  - text: kongctl configuration reference guide
    url: /kongctl/config/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: Use kongctl and deck for full API platform management
    url: /kongctl/kongctl-and-deck/
---

## Authenticate to {{site.konnect_short_name}}

Before you can manage resources, authenticate to {{site.konnect_short_name}} using the browser-based device flow:

```bash
kongctl login
```

This command will provide you with a URL you can open in your browser to authorize and activate kongctl in your organization. 

After completing the authorization, you can verify access by invoking the `get me` command which retrieves information for the authorized account:

```bash
kongctl get me
```

This is the typical structure of a kongctl command. The CLI uses a natural language structure that uses the following pattern:
```bash
kongctl <verb> <product/resource> <flags> <arguments>
```

## View existing resources

The `get` verb is commonly used to view resources defined in your organization. 

For example, list all Dev Portals in your organization:

```bash
kongctl get portals
```

If you are using a new account, you should see an empty response, otherwise the Dev Portals you have access to
will be displayed. 

kongctl commands support different output formats, including `json`, `yaml`, or `text`. The same `get` command will output the data in `json` format if you run the following:

```bash
kongctl get portals --output json
```

If you have a new {{site.konnect_short_name}} account that doesn't have any Dev Portals, this will return an empty JSON array (`[]`).

## Create resources declaratively

The kongctl declarative management system operates by taking resource configurations as input, planning
changes to authorized {{site.konnect_short_name}} organizations, and then applying those changes automatically
in the proper order to satisfy resource parent/child and other resource relationships.

### Preview changes with diff

Input configuration is typically stored in files and loaded into kongctl with the `--filename` flag. For the purposes of this guide, you can pass the configuration directly to the commands on `STDIN`. The following
command calculates a [plan](/kongctl/declarative/#plan-based-approach) for your organization with a basic Dev Portal declaration and displays a human-friendly
printout showing what changes _will be_ applied. 

```bash
echo 'portals:
  - ref: getting-started-portal
    name: "My First Portal"
    display_name: "The Getting Started Dev Portal"
	  description: "My first declaratively managed Dev Portal"' | kongctl diff -f -
```

The results of the diff should look like the following:

```text
Plan: 1 to add, 0 to change

=== Namespace: default ===
+ [1:c:portal:getting-started-portal] portal "getting-started-portal" will be created
  authentication_enabled: true
  rbac_enabled: false
  auto_approve_developers: false
  auto_approve_applications: false
  name: "My First Portal"
  display_name: "The Getting Started Portal"
  description: "My first declaratively managed portal"
  protection: disabled
```
{:.no-copy-code}

No resources in your organization have been created or modified, this is simply showing you a human readable
form of the plan that would be enacted if you applied the configuration.

### Apply the configuration

The `apply` command executes planned changes (create and update operations _only_) against the authorized organization. 
If we pass the same configuration to the `apply` command, kongctl will present you with the planned changes 
and prompt you for confirmation before executing them.

```bash
echo 'portals:
  - ref: getting-started-portal
    name: "My First Portal"
    display_name: "The Getting Started Dev Portal"
	  description: "My first declaratively managed Dev Portal"' | kongctl apply -f -
```

The confirmation and prompt will look like the following:

```bash
RESOURCE CHANGES
----------------------------------------------------------------------
Namespace: default (1 changes: 1 create)
  portal (1 resources):
    + getting-started-portal

SUMMARY
----------------------------------------------------------------------
  Total changes: 1
  Namespaces affected: 1
  Resources to create: 1

  Resource breakdown:
    portal: 1

CONFIRM?
----------------------------------------------------------------------
Do you want to continue? Type 'yes' to confirm:
```
{:.no-copy-code}

Type `yes` and press Enter to create the resources:

```bash
Executing changes:
[1/1] [namespace: default] Creating portal: getting-started-portal... ✓

Complete.
Executed 1 changes.
```
{:.no-copy-code}

## View applied changes

Now that you've created a Dev Portal, running the `get` operations again should yield results:

```bash
kongctl get portals --output json
```

Your results should look similar to the following:

```json
[
  {
    "authentication_enabled": true,
    "auto_approve_applications": false,
    "auto_approve_developers": false,
    "canonical_domain": "d6a3e6b6bc64.us.kongportals.com",
    "created_at": "2026-02-06T18:06:12.924Z",
    "default_api_visibility": "private",
    "default_application_auth_strategy_id": null,
    "default_domain": "d6a3e6b6bc64.us.kongportals.com",
    "default_page_visibility": "private",
    "description": "My first declaratively managed portal",
    "display_name": "The Getting Started Portal",
    "id": "ca9e25a5-67ed-4b3e-b94a-3f8977557780",
    "labels": {
      "KONGCTL-namespace": "default"
    },
    "name": "My First Portal",
    "rbac_enabled": false,
    "updated_at": "2026-02-06T18:06:12.924Z"
  }
]
```
{:.no-copy-code}

Congratulations! You just went from zero to managing {{site.konnect_short_name}} resources with kongctl.
