---
title: "Bot Detector"
content_type: reference
layout: reference
tech_preview: true
description: "Learn how Bot Detector identifies and manages automated bot traffic on Dedicated Cloud Gateways."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect
min_version:
  gateway: '3.10'

related_resources:
  - text: Dedicated Cloud Gateways reference
    url: /dedicated-cloud-gateways/reference/
  - text: Dedicated Cloud Gateways public network architecture and security
    url: /dedicated-cloud-gateways/public-network/
  - text: IP Restriction
    url: /plugins/ip-restriction/
tags:
  - dedicated-cloud-gateways
faqs:
  - q: Does Bot Detector replace my WAF?
    a: No. Bot Detector is meant to handle bot traffic while WAFs complement it by _____.
---

Bot Detector is a built-in Dedicated Cloud Gateway capability that identifies automated traffic using signals like user agents, request paths, and JA4 fingerprints. 
Unlike the [IP Restriction plugin](/plugins/ip-restriction/), which requires you to know the specific IPs or CIDR ranges you want to allow or deny, Bot Detector identifies bot traffic from the shape of the request itself, so you don't need to enumerate bad actors in advance.

Bot Detector is a built-in capability, not a plugin, that an Org Admin can enable or disable for the {{site.konnect_short_name}} org in the [Labs](https://cloud.konghq.com/global/organization/labs) UI and then Dedicated Cloud Gateway control planes can decide to enable it on a per control plane basis.

Use Bot Detector to:
* **Reduce cost from automated traffic**: Block traffic identified as bots before it reaches your upstream services and inflates your Dedicated Cloud Gateway usage. Requests blocked by Bot Detector aren't counted toward your usage. Detections recorded in monitoring mode are counted normally.
* **Evaluate before you enforce**: Run in monitoring mode to see what Bot Detector would have blocked, so you can build confidence in the results before switching to block mode.
* **Ensure trusted traffic isn't blocked**: Create a passthrough rule for a known partner IP, integration, or user agent so it's never blocked.
* **Investigate why a request was flagged**: Use the Detections view to see the path, IP, user agent, and matched rule behind any detection, and promote it into a passthrough rule if it's a false positive.
* **Limit exposure while you evaluate**: Enable Bot Detector on a single control plane, leave the rest untouched, and expand once you're satisfied with the results.

## How it works

Bot Detector uses it's own built-in rules as well as any custom rules you create to detect bot traffic.
The built-in rules are maintained and updated by Kong.
Kong-managed rules cover four broad categories of detection:

* **User-agent signals**: Requests from known security scanners, headless browsers and automation frameworks, self-declared bots, and spoofed or malformed browser identities
* **Request-shape signals**: Requests missing headers a real browser would send, or claiming to be a browser without behaving like one
* **Vulnerability probes**: Requests targeting sensitive paths, admin panels, config files, and backup files
* **Injection patterns**: Requests with matching SQL injection, path traversal, command injection, and encoded-payload variant patterns

Trusted crawlers, such as Googlebot, Bingbot, ClaudeBot, DuckDuckBot, and well-known uptime monitors, are allow listed. 

You can create custom rules that match on a single condition (IP, path, user agent, or JA4 fingerprint).
Your custom rules takes precedence over Kong-managed rules, so matching traffic is never blocked.

Bot Detector runs in one of two modes:

* **Monitoring (default)**: Bot Detector evaluates every request to your Dedicated Cloud Gateway control plane and records what it would have done, without affecting traffic. Use this mode to review detections and build confidence before blocking anything.
* **Passthrough:** ?
* **Block**: Requests that match a block rule are rejected with a `403` response.

## Using Bot Detector

Overview of steps at a glance. Link to the sections on the page.

1. Enable it in Labs and on a public DCGW control plane. 
1. Something about how to assess detections/viewing stuffs.
1. (Optional) Something about IP Restrictions plugin and using it with Bot Detector.
1. Something about creating any custom rules for [add specific examples] based on your observations from monitoring/other use case.
1. Something about moving to blocking.

## Enable Bot Detector

Bot Detector is scoped to the control plane, not the organization. 
This allows you to enable it on a single control plane to evaluate it, leave your other control planes untouched, and expand once you're satisfied with the results.

{% navtabs "bot-detector" %}
{% navtab "API" %}
<!-- TODO: fill in API steps once endpoint links are available -->
{% endnavtab %}
{% navtab "UI" %}
Bot Detector is enabled first at the organization level through {{site.konnect_short_name}} Labs, and then per control plane.

1. From the organization dropdown, click **Manage organization**.
1. Click the **Labs** tab.
1. Click **Bot Detector**.
1. Click **Enable feature**.
1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **Control planes**.
1. Click the Dedicated Cloud Gateway control plane you want to enable Bot Detector for.
1. From the **More** tab, select **Bot Detector**.
1. Click **Enable bot detector**.

Once enabled, a control plane's Bot Detector page starts in monitoring mode. To switch modes, click **Enable blocking**.
To turn Bot Detector off entirely, from the **Actions** dropdown menu, select "Disable bot detector".
{% endnavtab %}
{% endnavtabs %}

## Assessing detections 

Bot Detector provides two views for reviewing traffic:

* **Overview**: An aggregate dashboard showing status, mode, active rules, and request totals (monitored and blocked) over a selectable time range.
* **Detections**: A filterable, exportable log of every evaluated request, including the path, action taken, timestamp, IP, user agent, and matched rule. You can promote any detection directly into a passthrough rule if it turns out to be a false positive.

## Configure rules

Notes: Will need answers on some of the rule specifics. How do you know you need to create a rule? Detections will also need answers, like when to switch, what you're looking for, how to interpret, etc. Limitations will need answers to the rules (are customer blocking rules allowed?) and a general look over for accuracy.

{% navtabs "rules" %}
{% navtab "API" %}
<!-- TODO: fill in API steps once endpoint links are available -->
{% endnavtab %}
{% navtab "UI" %}
placeholder
{% endnavtab %}
{% endnavtabs %}

## Switching to blocking bot traffic

While Bot Detector is enabled, you can switch between monitoring and block mode at any time. 
Mode changes propagate to data planes on their next pull cycle (up to five minutes). 
No data plane restart or redeploy is required.

{% navtabs "rules" %}
{% navtab "API" %}
<!-- TODO: fill in API steps once endpoint links are available -->
{% endnavtab %}
{% navtab "UI" %}
placeholder
{% endnavtab %}
{% endnavtabs %}

bit about monitoring traffic still and how to remediate anything that is a false positive.