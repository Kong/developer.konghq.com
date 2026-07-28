---
title: "How to set different route \"host\" values depending on the environment using deck"
content_type: support
description: As of version 1.7.0, deck makes it possible to use environment variables to set values inside the deck yaml file.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
published: false
tldr:
  q: How do I set different route host values depending on the environment when using decK?
  a: |
    Since decK 1.7.0, you can reference an environment variable inside the decK YAML file, for example `hosts: [${{ env "DECK_HOSTS" }}]`, and set that variable to a different value per environment before running `deck sync`.
---

## Overview

When using deck, is it possible to set different route `hosts` values depending on the environment against which deck is run?

## Steps

As of version 1.7.0, deck makes it possible to use environment variables to set values inside the deck yaml file.

For the route `hosts` value, an example would be:

```yaml

 hosts: [${{ env "DECK_HOSTS" }}]
```

and set the relevant env variable before executing a `deck sync` like this:

```bash

export DECK_HOSTS="'my.host1.com', 'my.host2.com'"
```

This would be valid for any environment variable to be used as an array.
