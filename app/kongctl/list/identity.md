---
title: kongctl list identity
description: "List Kong Identity resources."
content_type: reference
layout: reference


works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/list/

related_resources:
  - text: kongctl list commands
    url: /kongctl/list/
  - text: kongctl adopt identity
    url: /kongctl/adopt/identity/
  - text: kongctl get identity
    url: /kongctl/get/identity/
  - text: kongctl import identity
    url: /kongctl/import/identity/
  - text: kongctl inspect identity
    url: /kongctl/inspect/identity/
---

List Kong Identity resources.

kongctl provides the following tools for listing Kong Identity resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list identity auth-server](/kongctl/list/identity/#kongctl-list-identity-auth-server)
    description: "List or get Kong Identity authorization servers."
  - command: |
      [kongctl list identity directory](/kongctl/list/identity/#kongctl-list-identity-directory)
    description: "List or get Kong Identity directories in the configured region."
  - command: |
      [kongctl list identity group](/kongctl/list/identity/#kongctl-list-identity-group)
    description: "List or get Kong Identity groups in a directory."
  - command: |
      [kongctl list identity principal](/kongctl/list/identity/#kongctl-list-identity-principal)
    description: "List or get principals in a Kong Identity directory."
  - command: |
      [kongctl list identity trusted-idp](/kongctl/list/identity/#kongctl-list-identity-trusted-idp)
    description: "List or get directory Trusted IdP configuration."
  - command: |
      [kongctl list identity vault](/kongctl/list/identity/#kongctl-list-identity-vault)
    description: "Inspect directory Token Vault keys and providers."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/list/identity/index.md %}

### kongctl list identity auth-server

List or get Kong Identity authorization servers.

{% include_cached /kongctl/help/list/identity/auth-server.md %}

### kongctl list identity directory

List or get Kong Identity directories in the configured region.

{% include_cached /kongctl/help/list/identity/directory.md %}

### kongctl list identity group

List or get Kong Identity groups in a directory.

{% include_cached /kongctl/help/list/identity/group.md %}

### kongctl list identity principal

List or get principals in a Kong Identity directory.

{% include_cached /kongctl/help/list/identity/principal.md %}

### kongctl list identity trusted-idp

List or get directory Trusted IdP configuration.

{% include_cached /kongctl/help/list/identity/trusted-idp.md %}

### kongctl list identity vault

Inspect directory Token Vault keys and providers.

{% include_cached /kongctl/help/list/identity/vault.md %}
