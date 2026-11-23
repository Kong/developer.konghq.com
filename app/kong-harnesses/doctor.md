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

The `doctor` command checks that a profile works from start to end, and shows a fix beside each problem that it finds.
It checks the profile, the sign-in, the settings of each agent CLI, and the gateway.
For a profile that signs in with an identity provider, it also checks that the token endpoint of the identity provider answers.
To act on each finding, see [Troubleshoot kong-harnesses](/kong-harnesses/troubleshooting/).
For what each exit code of `doctor` means, see [Exit codes of doctor](/kong-harnesses/errors/#exit-codes-of-doctor).

## Command usage

{% include_cached kong-harnesses/help/doctor/index.md %}

To send the `--report` output to Kong Support, see [kong-harnesses support](/kong-harnesses/support/).
