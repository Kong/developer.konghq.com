---
title: Excluding specific services or routes from a global plugin
content_type: support
published: false
description: No, a globally enabled plugin applies to all traffic.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Can a global plugin have exclusions?
  a: |
    No. A globally enabled plugin always applies to all traffic; it has no built-in exclusion mechanism. However, a plugin configured at a lower level (service or route) overrides the global plugin's configuration for that entity, so you can achieve a similar effect by adding a differently configured instance of the plugin at the service or route level.
related_resources: []
---

## Can a global plugin have exclusions?

Can a plugin enabled globally have exclusions? Scenario: I have 10 services and want a plugin to apply to 9 of them. It would be easier to enable a global plugin and add one exception / exclusion instead of applying individually to 9 services. Is this possible?

No, a globally enabled plugin applies to all traffic. However, its configuration depends on the entities it is associated with. Values from global plugins can be overridden by plugins configured at a lower level, such as on a service or route.

For more details, please review the documentation on plugin precedence .
