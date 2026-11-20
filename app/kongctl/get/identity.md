---
title: kongctl get identity
description: "List or get Kong Identity resources."
content_type: reference
layout: reference


works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
  - text: kongctl adopt identity
    url: /kongctl/adopt/identity/
  - text: kongctl import identity
    url: /kongctl/import/identity/
  - text: kongctl inspect identity
    url: /kongctl/inspect/identity/
  - text: kongctl list identity
    url: /kongctl/list/identity/
---

List or get Kong Identity resources.

kongctl provides the following tools for retrieving Kong Identity resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get identity auth-server](/kongctl/get/identity/#kongctl-get-identity-auth-server)
    description: "List or get Kong Identity authorization servers."
  - command: |
      [kongctl get identity directory](/kongctl/get/identity/#kongctl-get-identity-directory)
    description: "List or get Kong Identity directories in the configured region."
  - command: |
      [kongctl get identity group](/kongctl/get/identity/#kongctl-get-identity-group)
    description: "List or get Kong Identity groups in a directory."
  - command: |
      [kongctl get identity principal](/kongctl/get/identity/#kongctl-get-identity-principal)
    description: "List or get principals in a Kong Identity directory."
  - command: |
      [kongctl get identity trusted-idp](/kongctl/get/identity/#kongctl-get-identity-trusted-idp)
    description: "List or get directory Trusted IdP configuration."
  - command: |
      [kongctl get identity vault](/kongctl/get/identity/#kongctl-get-identity-vault)
    description: "Inspect directory Token Vault keys and providers."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/identity/index.md %}

### kongctl get identity auth-server

List or get Kong Identity authorization servers.

{% include_cached /kongctl/help/get/identity/auth-server.md %}

### kongctl get identity directory

List or get Kong Identity directories in the configured region.

{% include_cached /kongctl/help/get/identity/directory.md %}

### kongctl get identity group

List or get Kong Identity groups in a directory.

{% include_cached /kongctl/help/get/identity/group.md %}

### kongctl get identity principal

List or get principals in a Kong Identity directory.

{% include_cached /kongctl/help/get/identity/principal.md %}

### kongctl get identity trusted-idp

List or get directory Trusted IdP configuration.

{% include_cached /kongctl/help/get/identity/trusted-idp.md %}

### kongctl get identity vault

Inspect directory Token Vault keys and providers.

{% include_cached /kongctl/help/get/identity/vault.md %}
