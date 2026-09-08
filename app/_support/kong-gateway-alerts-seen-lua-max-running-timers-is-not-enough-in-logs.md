---
title: "Kong Gateway: Alerts seen `lua_max_running_timers is not enough` in logs, Gateway no longer working"
content_type: support
description: "How to resolve `lua_max_running_timers are not enough` alerts in Kong Gateway logs by increasing the timer limit, disabling Vitals, or resolving upstream DNS and latency issues."
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do I see `lua_max_running_timers are not enough` alerts in Kong Gateway logs, and why has the Gateway stopped accepting requests?
  a: |
    This happens when the timer system (set in the Nginx layer) runs out of timers for the traffic volume, usually combined with memory pressure, Vitals being enabled, DNS lookup failures, or delayed upstream responses. The recommended fix is to raise `lua_max_running_timers` above its default of 4096 via a custom Nginx template, increasing it in increments of no more than 4096 at a time and testing after each change. Disabling Vitals and resolving DNS/upstream latency issues are additional workarounds if memory can't be increased.
related_resources: []
---

## Problem

We are experiencing various performance-related issues in our Kong Gateway ranging from increased latency to increased transaction failure rates to lack of Vitals information and more. In the worst-case scenario, our Gateway appears to be 'down' and unable to accept new requests.

When looking at the Gateway logs, we see the following example log entries:

```
[alert] 2066#0: lua failed to run timer with function defined at @/usr/local/share/lua/5.1/kong/plugins/datadog/handler.lua:52: 4096 lua_max_running_timers are not enough
[alert] 2066#0: lua failed to run timer with function defined at @/usr/local/share/lua/5.1/kong/runloop/balancer/targets.lua:234: 4096 lua_max_running_timers are not enough
[alert] 2066#0: lua failed to run timer with function defined at @/usr/local/share/lua/5.1/resty/counter.lua:33: 4096 lua_max_running_timers are not enough
```

## Cause

These errors/alerts can occur when the timers system in Kong Gateway (specifically set in the Nginx component) is insufficient for the amount of traffic being received, combined with a mix of memory resources allocated to the node as well as other factors such as the use of Vitals or if there are a lot of DNS lookup errors or significantly delayed responses from upstream targets - all of this pools into consuming more timers than desired which will lead to a multitude of other issues over time.

## Solution

To resolve the situation, there are a few options:

1. Increase `lua_max_running_timers` in Kong Gateway using a custom Nginx template
2. Disable Vitals in the Kong Gateway node
3. Resolve DNS lookup failures, typically this means removing outdated hostname entries from the Service URLs / Upstream Targets
4. Resolve upstream latencies which can affect the timer usage in Kong as well

Note: Vitals now defaults to fully disabled on current Kong Gateway Enterprise releases (confirmed on 3.14.0.0), so option 2 below only applies if Vitals has been explicitly enabled — on a stock, default-config install it isn't contributing to timer usage at all.

While the first option may not be as easy as the rest, it is the recommended option especially in a situation where the traffic and environmental impacts may have surpassed the default configuration for Kong Gateway timers and simply needs to be increased to accommodate the volume of activity. This first option does generally require a bit more memory or at least sufficiently free memory for the environment. Thorough testing should be completed as the timers are increased. The other options are additional workarounds and may be more desirable if this is just a temporary increase in traffic for example causing the spikes in timer usage.

For option #1: In an environment where memory is either under utilized or can easily be expanded, the `lua_max_running_timers` can be increased from the 4096 default to a higher value. As more timers when in-use will consume more memory, we strongly recommend this be increased in intervals of generally no more than 4096 at a time. So this would mean increasing from 4096 to 8192 and then next 12288 before increasing it further if needed.

To increase the `lua_max_running_timers`, simply use a custom Nginx template as documented. This includes copying the `nginx_kong.lua` template and customizing the values for `lua_max_running_timers` from 4096 to a greater number. The default line is this one:

```nginx
lua_max_running_timers 4096;
```

and changing it to the following line as the next step in testing:

```nginx
lua_max_running_timers 8192;
```

If after testing that change the issue does not re-appear, then you can leave it at that number. If it still re-appears then we recommend doubling it again to 16384.

Other options: If memory is unable to be increased and there is not much available left in the nodes, then the other methods (2-4) above may be executed as an alternative workaround. As these alternatives are more environmental in nature though, the effectiveness of them will vary from environment to environment and option 1 still may be the required action to resolve the issue.

Long-term, it is strongly recommended to upgrade as soon as possible from 2.x to 3.x as a new timer library was introduced in 3.0. The timer issues reported in 2.x versions have not been seen in 3.x due to the rewritten timer library which uses far less timers than in earlier versions along with other performance improvements as well. Kong has written a blog post about the new scalable timer library in 3.0 for further reading.
