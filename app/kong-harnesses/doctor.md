---
title: kong-harnesses doctor
description: Check one profile end to end and report each fix beside each finding.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `doctor` command checks one profile end to end: the profile, the sign-in, the client, the gateway and, for a profile that signs in through an identity provider, the identity provider.
`doctor` reaches the network, reports each finding beside its fix, and can write the report as JSON.

## CA bundle checks

`doctor` also checks each CA bundle file that `SSL_CERT_FILE` or `NODE_EXTRA_CA_CERTS` names.
`doctor` reports a result for each HTTPS server of the profile: the gateway, the identity provider when the profile uses one, and the profile server when the profile keeps its HTTPS import URL.
A profile that an earlier release imported doesn't keep that URL.
A missing or unreadable file gets a separate result.

`doctor` checks the `NODE_EXTRA_CA_CERTS` file for each client of the profile that reads the variable, with the root CAs that the client trusts when the variable is set.
A failure names the client.
`doctor` reads the `NODE_EXTRA_CA_CERTS` value of each client from the following places:

{% table %}
columns:
  - title: Client
    key: client
  - title: Source of the value
    key: source
rows:
  - client: "{{ site.claude_code }}"
    source: The `env` block of the [user settings](/kong-harnesses/developer-computer-changes/#claude-code-settings) when that block sets the variable, or else the environment.
  - client: OpenCode
    source: The environment, or the environment of the service when OpenCode runs as a background service.
  - client: omp
    source: |
      The environment.
      When the environment doesn't set the variable, the first value that isn't empty in the [`.env` files that omp reads](/kong-harnesses/private-certificate-authorities/#agent-clis-that-need-more-than-the-system-trust-store).
      `doctor` uses the directory where you run `doctor` as the directory where omp starts.
{% endtable %}

## Command usage

{% include_cached kong-harnesses/help/doctor/index.md %}
