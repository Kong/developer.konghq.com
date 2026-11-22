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
It also checks each CA bundle file that `SSL_CERT_FILE` or `NODE_EXTRA_CA_CERTS` names, with a result for each of these servers that uses HTTPS and for the profile server of a profile imported from an HTTPS URL.
A missing or unreadable file gets a separate result.
The check of the `NODE_EXTRA_CA_CERTS` file also counts the root CAs that Node.js has built in, as Node.js adds the file to them.
It reaches the network, reports each finding beside its fix, and can write the report as JSON.

## Command usage

{% include_cached kong-harnesses/help/doctor/index.md %}
