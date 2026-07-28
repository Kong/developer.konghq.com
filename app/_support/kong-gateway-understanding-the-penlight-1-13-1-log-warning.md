---
title: "Kong Gateway: Understanding the Penlight 1.13.1 Log Warning"
content_type: support
published: false
description: You do not need to be worried about this message, it is simply informational.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Should I be concerned about the `Penlight 1.13.1` `pl.xml` deprecation warning in my logs?
  a: |
    No. The warning is informational and refers to Kong's tested use of the `pl.xml` module from the Penlight library for XML parsing in some plugins. No action is required.
faqs:
  - q: What does this mean and should I be concerned?
    a: |
      You do not need to be worried about this message, it is simply informational. This line is referring to the usage of a file `pl.xml` in a Lua library known as Penlight. This is a package that Kong utilizes (and has tested) in some of our plugins, and this instance is for XML parsing.
---

## Understanding the Penlight 1.13.1 log warning

I am looking through my logs and I see the following warning:

```
[warn] 887386#0: [kong] [C]:-1 [Penlight 1.13.1] the contents of module 'pl.xml' has been deprecated, please use a more specialized library instead (deprecated after 1.11.0, scheduled for removal in 2.0.0)
```
