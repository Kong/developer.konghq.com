---
title: Controlling the hybrid configuration update frequency
content_type: support
description: How the `db_update_frequency` parameter controls how often {{site.base_gateway}} pushes configuration updates from the Control Plane to Data Planes in Hybrid mode.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "`db_update_frequency` configuration reference"
    url: /gateway/configuration/#db-update-frequency
tldr:
  q: How can I control the frequency of configuration updates between the Control Plane and Data Plane in Kong Hybrid mode?
  a: |
    Set the `db_update_frequency` parameter, which controls how often Kong checks the datastore for updated entities. In Hybrid mode, the same parameter controls how frequently the Control Plane pushes configuration changes to the Data Plane, for example `db_update_frequency=30` to sync every 30 seconds.
---

## Problem

When using a Hybrid installation of Kong, how can the frequency of configuration updates between the Control Plane and Data Plane be controlled?

## Solution

When using a Classic deployment of Kong where all nodes have access to the datastore, the frequency at which the database is checked for updated entities is controlled by the `db_update_frequency` parameter.

The same parameter is used in a Hybrid deployment to control how frequently the Control Plane will push configuration changes to the Data Plane. As an example, if you only wish to synchronize the configuration to the Data Plane every 30 seconds, then set the Kong configuration like this:

```
db_update_frequency=30
```

This setting will make the Data Plane configuration push sleep for the configured `db_update_frequency` time.
