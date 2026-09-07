---
title: "Kong Gateway: Rate Limiting By Header Value w/ Key Auth Plugin"
content_type: support
description: Combine the Rate Limiting Advanced plugin with the Key Auth plugin and Consumer Groups to rate limit requests by a header's value.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I rate limit requests by a header's value combined with the Key Auth plugin in Kong Gateway?
  a: |
    Combine the Rate Limiting Advanced plugin with the Key Auth plugin and Consumer Groups: create a consumer with a `key-auth` credential, add the consumer to a Consumer Group, and attach a Rate Limiting Advanced policy to that group. Scope both plugins to the specific route or service you want to protect — leaving them unscoped creates a global plugin that affects unrelated traffic too.
---

## Problem

My goal is to use the Rate Limit Advanced Plugin, but I want to be able to control rate by the value of a passed header's value. How could I accomplish this?

## Solution

We need to leverage not just the Rate Limiting Advanced Plugin, but combine it with the Key Auth Plugin and tack on Consumer Groups.

The below example will include a single consumer with its 1 key, and a single consumer group but this can be scaled up to any number of consumers and their groups along with unique policies. Just don't forget to add the groups to your RLA Plugin!

First I have generated a simple service plus route to an httpbin-compatible upstream (`httpbin.org` is a commonly-used public demo target for this kind of walkthrough, but is currently unreliable/unreachable — use any httpbin-compatible host you have available, such as a local `kennethreitz/httpbin` container):

```bash

curl -i -s -X POST http://localhost:8001/services \
 --data name=httpbin \
 --data url='http://httpbin'
```

```bash

curl -i -X POST http://localhost:8001/services/httpbin/routes \
 --data 'paths[]=/test' \
 --data name=bin-route
```

Now we want to create a consumer:

```bash

curl -X POST http://localhost:8001/consumers/ \
 --data username=rumpus
```

Next we should add our two plugins, Rate Limiting Advanced, and Key Auth:

```bash

curl -X POST http://localhost:8001/plugins/ \
 --data "name=rate-limiting-advanced" \
 --data "route.name=bin-route" \
...
```

```bash

curl -X POST http://localhost:8001/plugins/ \
   --data "name=key-auth"  \
   --data "config.key_names=x-special-header" \
   --data "route.name=bin-route"
```

**Note:** the plugin creation calls above omit a `route.id`/`route.name`/`service.id` scope, which creates a **global** plugin applied to every route on the Gateway, not just this one — on a Gateway with any other traffic already flowing through it, this would immediately start requiring an API key (and enforcing rate limits) on completely unrelated routes too. Scope both the `key-auth` and `rate-limiting-advanced` plugin instances to the route (or service) you actually intend to protect, as shown above, unless you specifically want the behavior applied globally.

We do not need to be very concerned with the configurations of the Rate Limiting Plugin as we will have a Consumer Group with a Policy that overrides those configs.

Also, keep note of the Key Auth `config.key_names`, I set mine to: `x-special-header`.

With these pieces in place, we should now generate a key for our Consumer:

```bash

curl -X POST http://localhost:8001/consumers/rumpus/key-auth \
 -d key=rumpus1
```

Then we need to generate a Consumer Group to represent the bucket for limiting:

```bash

curl -i -X POST http://localhost:8001/consumer_groups \
--data name=Gold
```

And Add the Consumer to this Group:

```bash

curl -i -X POST http://localhost:8001/consumer_groups/Gold/consumers \
--data consumer=rumpus
```

This Consumer Group now needs a Policy for Rate Limiting, this is the limiting our header value will be used to adhere to:

```bash

curl -i -X POST http://localhost:8001/consumer_groups/gold/plugins/  \
--data name=rate-limiting-advanced \
--data config.limit=5 \
--data config.window_size=15 \
--data config.window_type=sliding \
--data config.retry_after_jitter_max=0 \
```

And the Consumer Group needs to be applied to the Rate Limiting Advanced Plugin, you can do this by navigating back to your plugin and adding the Consumer Group name to the rate limiting advanced plugin's `config.consumer_groups`, mine was Gold

Don't forget to turn on enforcement!

Finally, we can get to testing:

```bash

curl -i http://localhost:8000/test -H "x-special-header:rumpus1"
HTTP/1.1 200 OK
...
X-RateLimit-Limit-15: 5
RateLimit-Remaining: 4
X-RateLimit-Remaining-15: 4
RateLimit-Reset: 6
RateLimit-Limit: 5
...
{
...
  "headers": {
    "Accept": "*/*",
    "Connection": "keep-alive",
    "Host": "httpbin",
    "User-Agent": "curl/8.7.1",
    "X-Consumer-Id": "56cd5769-4b7e-40d4-ba88-d9ad6e45b334",
    "X-Consumer-Username": "rumpus",
    "X-Credential-Identifier": "5b24e04d-dfe8-4bc8-9942-2a2099b9532c",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/test",
    "X-Forwarded-Prefix": "/test",
    "X-Kong-Request-Id": "9be40d2d4d740756729a6144dc1b3c38"
  },
  ...
}
```

**Note on Kong Gateway 3.14.0.0:** `X-Special-Header` (the actual API key) is intentionally **not** present in the headers Kong forwards upstream above. As of 3.14.0.0, `hide_credentials` now defaults to `true` on newly-created `key-auth` plugin instances (previously it defaulted to `false`), so unless you explicitly set `config.hide_credentials=false`, the credential header will not be echoed back by the upstream the way it is in older examples.

And to prove it, we can alter this header value:

```bash

curl http://localhost:8000/test -H "x-special-header:rumpus"
{
  "message":"Unauthorized",
  "request_id":"ad43d53a1aff9c175450092ed298af21"
}
```

**Note on Kong Gateway 3.14.0.0:** the `key-auth` plugin's error message for an invalid/unrecognized key is `"Unauthorized"`, not the older `"Invalid authentication credentials"` text shown in some older examples — the response body and behavior above are otherwise unchanged.
