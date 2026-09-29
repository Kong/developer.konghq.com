---
title: How to set `ulimit` on Kong server
content_type: support
description: "`ulimit` is the number of open file descriptors per process."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
published: false
tldr:
  q: How do I set the `ulimit` (open file descriptor limit) for the Kong server?
  a: |
    Kong logs a warning when the open file descriptor limit is too low. Set `ulimit -n` to at least `4096` on the server before starting Kong, ideally during server/node preparation, and restart Kong after changing it.
---

## Overview

You will see the below warning message if the `ulimit` is not enough:

```
[warn] ulimit is currently set to "1024". For better performance set it to at least "4096" using "ulimit -n"
```

## Steps

`Ulimit` is the number of open file descriptors per process.

So you can use the below Linux command to set `ulimit` on your server.

The number should be at least 4096.

```bash

ulimit -n {number}
```

After resetting `ulimit` on the server, please restart Kong.

The best time to set `ulimit` is in the server/node preparation/installing phase before installing Kong on that server.
