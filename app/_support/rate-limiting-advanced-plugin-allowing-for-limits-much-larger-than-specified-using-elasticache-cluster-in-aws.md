---
title: Rate Limiting Advanced plugin allowing for limits much larger than specified using ElastiCache cluster in AWS
content_type: support
description: "Why the `Rate Limiting Advanced` plugin allows more requests than configured when using an AWS ElastiCache cluster, and how to fix it by specifying the cluster address correctly."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the Rate Limiting Advanced plugin allow more requests than the configured limit when using an AWS ElastiCache cluster?
  a: |
    This happens when the Redis cluster is specified as a plain host in the plugin's Redis config, which causes Kong to create multiple keys for the same limit window and count requests separately. Set the cluster hostname (without a port) under `Config.Redis.Cluster Addresses` instead, and move the port to the cluster address, so only one key is used per window.
---

## Problem

When using the Rate Limiting Advanced plugin with an ElastiCache cluster in AWS we are specifying a limit of 10 however we are passing 15-20 transactions before receiving the error "429 - Too many requests".

```json
{
	"message": "API rate limit exceeded"
}
```

For example we have a limit of 10 and a window size of 30. About 20 of these requests will pass inside that 30 second window.

This type of behavior can be experienced if the Cluster is being specified as a host inside the Rate Limiting Advanced plugin.

The reason this occurs is because it is creating multiple keys for storage allowing for more than the specified limit. Under `redis-cli` we can run the `keys` command to confirm:

```
keys *
1) "1660576260:30:abHx1lXb5BTdBjfke34BlNInAdajk350L"
2) "1660576290:30:abHx1lXb5BTdBjfke34BlNInAdajk350L"
```

## Solution

To correct this, we would need to grab the Cluster hostname from AWS and specify it under the value `Config.Redis.Cluster Addresses`.

**Note:** You will need to remove the port from `Config.Redis.Port` and add it to the `cluster_hostname` specified under `Config.Redis.Cluster Addresses`, like the example above.

Now while testing we will have the exact limit hit during the window size that is configured on the Rate Limiting Advanced plugin.

Again to confirm this, we can connect to our `redis-cli` and run the `keys` command:

```
keys *
1) "1660576830:30:abHx1lXb5BTdBjfke34BlNInAdajk350L"
```

This time we only see 1 key being stored.
