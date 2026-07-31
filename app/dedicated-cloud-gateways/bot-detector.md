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
  - q: Does Bot Detector replace the IP Restriction plugin?
    a: No. Bot Detector is a complement to the [IP Restriction plugin](/plugins/ip-restriction/). Bot Dectector can block bot traffic from the shape of the request whereas the IP Restriction plugin can be used when you know the exact IPs or CIDR ranges you want to allow list.
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
* **Monitoring (default)**: Bot Detector evaluates every request to your Dedicated Cloud Gateway control plane and records what it would have done (either block or passthrough), without affecting traffic. Use this mode to review detections and build confidence before blocking anything.
* **Block**: Requests that match a block rule are rejected with a `403` response. All others passthrough.

You decide when you want to switch from monitoring to blocking after you've established confidence in the results in monitoring mode.

## Using Bot Detector

The following are an overview of the general steps you should take to enable, monitor, and use Bot Detector:

1. Enable it in Labs and on a public Dedicated Cloud Gateway control plane. 
1. Monitor detections for any false positives or valid traffic that is marked as blocked.
1. (Optional) Allow list IPs with the IP Restrictions plugin as a complement to Bot Detector.
1. Create any custom rules from your observations while Bot Detector is in monitoring mode.
1. After you've gained confidence in monitoring mode, switch Bot Detector to blocking mode.

### Prerequisites

* To enable Bot Detector in Labs, you need the ___ role.
* To enable Bot Detector for a Dedicated Cloud Gateway control plane, you need the ___ role.
* A public Dedicated Cloud Gateway with a network configured.

### Enable Bot Detector

Bot Detector is enabled first at the organization level through {{site.konnect_short_name}} Labs, and then per control plane.
Because Bot Detector is scoped to the control plane, not the organization, this allows you to enable it on a single control plane to evaluate it, leave your other control planes untouched, and expand once you're satisfied with the results.

{% navtabs "bot-detector" %}
{% navtab "API" %}
Enabling Bot Detector for your organization in {{site.konnect_short_name}} Labs is only available in the UI. See the **UI** tab for this step.

Once Bot Detector is enabled for your organization, enable it for a control plane by sending a `POST` request to the `/waap/{cpId}/enabled` endpoint:

```sh
curl -X POST https://us.api.konghq.tech/bot-gline-manager/waap/$CONTROL_PLANE_ID/enabled \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "block_mode": false}'
```

Setting `block_mode` to `false` starts the control plane in monitoring mode.
{% endnavtab %}
{% navtab "UI" %}
1. From the organization dropdown, click **Manage organization**.
1. Click the **Labs** tab.
1. Click **Bot Detector**.
1. Click **Enable feature**.
1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **Control planes**.
1. Click the Dedicated Cloud Gateway control plane you want to enable Bot Detector for.
1. From the **More** tab, select **Bot Detector**.
1. Click **Enable bot detector**.

Once enabled, a control plane's Bot Detector starts in monitoring mode.
{% endnavtab %}
{% endnavtabs %} 

### Assessing detections 

After Bot Detector processes traffic in monitoring mode, it will populate the overview and detections dashboards with what it would have done to the traffic (passthrough or block).

Bot Detector provides two views for reviewing traffic:
* **Overview**: An aggregate dashboard showing status, mode, active rules, and request totals (monitored and blocked) over a selectable time range.
* **Detections**: A filterable log of every evaluated request, including the path, action taken, timestamp, IP, user agent, and matched rule. You can promote any detection directly into a passthrough rule using the action menu if it turns out to be a false positive.

TODO: Detections will also need answers, like when to switch, what you're looking for, how to interpret, etc.

### Configure rules

If while you are in monitoring mode, you see traffic that is marked incorrectly as `Block` or `Passthrough`, you can create custom rules to block or allow that traffic.
Additionally, if there are certain IPs you know need to passthrough (for example, an IP of a partner company), you can create rules for those.

These rules match on a single condition (IP, path, user agent, or JA4 fingerprint) and take precedence over Kong-managed rules. 
You can specify multiple match types per rule, but all conditions on a rule must match for the rule to apply.

The following table describes which match types you can set and some example values:
<!--vale off-->
{% table %}
columns:
  - title: Match type
    key: match_type
  - title: Description
    key: description
  - title: Exact match example
    key: exact_example
  - title: Regex example
    key: regex_example
rows:
  - match_type: IP address
    description: Matches a single client IP address.
    exact_example: "`203.0.113.5`"
    regex_example: Not supported
  - match_type: CIDR range
    description: Matches a range of client IP addresses in CIDR notation.
    exact_example: "`203.0.113.0/24`"
    regex_example: Not supported
  - match_type: JA4
    description: Matches a client's JA4 TLS fingerprint.
    exact_example: "`t13d1516h2_8daaf6152771_02713d6af862`"
    regex_example: "`t13d1516h2_.*`"
  - match_type: User agent
    description: Matches the request's `User-Agent` header.
    exact_example: "`curl/8.7.1`"
    regex_example: "`(?i)(bot|crawler)`"
  - match_type: Path
    description: Matches the request path.
    exact_example: "`/health`"
    regex_example: "`^/api/v[0-9]+/users$`"
{% endtable %}
<!--vale on-->

{% navtabs "rules" %}
{% navtab "API" %}
1. List your existing rules by sending a `GET` request to the `/waap/{cpId}/rules` endpoint:

   ```sh
   curl https://us.api.konghq.tech/bot-gline-manager/waap/$CONTROL_PLANE_ID/rules \
     -H "Authorization: Bearer $KONNECT_TOKEN"
   ```

1. Create a rule by sending a `POST` request to the `/waap/{cpId}/rule` endpoint. The following example creates a passthrough rule that matches a single path:

   ```sh
   curl -X POST https://us.api.konghq.tech/bot-gline-manager/waap/$CONTROL_PLANE_ID/rule \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "Allow health check path",
       "action": "passthrough",
       "priority": 100,
       "value": {
         "application_rules": {
           "paths": [
             { "match": "equals", "value": "/health" }
           ]
         }
       }
     }'
   ```

   * Set `"action"` to `"block"` to create a block rule instead.
   * Set `"match"` to `"regex"` to match a path, user agent, or JA4 fingerprint using a regular expression instead of an exact match.
   * To match on an IP address or CIDR range, use `"network_rules"` with `"ips"` or `"cidrs"` instead of `"application_rules"`.
   * Add more entries to `paths`, `user_agents`, `ja4`, `ips`, or `cidrs` to require multiple conditions on the same rule. All conditions on a rule must match for the rule to apply.
   * `"priority"` determines the order your rules are evaluated in relative to each other (higher integers runs sooner). It doesn't affect the position of Kong-managed rules, which always run after all your rules.
{% endnavtab %}
{% navtab "UI" %}
TODO:
Integer priority setting.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **Control planes**.
1. Click the Dedicated Cloud Gateway control with Bot Detector enabled.
1. From the **More** tab, select **Bot Detector**.
1. Click the **Rules** tab.
1. Click **New rule**.
1. For the Rule action settings, select one of the following:
   * **Block**: Denies requests that match the conditions.
   * **Passthrough**: Allows requests that match the conditions.
1. For the Match conditions settings, do the following:
   1. From the **Match type** dropdown menu, select a match type.
   1. In the **Value** field, enter the value you want to match.
   1. (Optional) To add more match conditions to a rule, click **Add another condition** and repeat the previous two steps.
      
      {:.warning}
      > When multiple conditions are configured on a rule, **all conditions** must match for a rule to apply.
1. Click **Save**.
{% endnavtab %}
{% endnavtabs %}

### Switching to blocking bot traffic

You can switch from monitoring to blocking mode after you've established confidence in the results in monitoring mode:
* Make sure your Gateway Services, Routes, and clients are configured correctly.
* Verify that good traffic is labelled as `Passthrough` and unwanted traffic is labeled as `Block`.

While Bot Detector is enabled, you can switch between monitoring and block mode at any time. 
Mode changes propagate to data planes on their next pull cycle (which can be up to five minutes). 
No data plane restart or redeploy is required.

{% navtabs "rules" %}
{% navtab "API" %}
Send a `POST` request to the same `/waap/{cpId}/enabled` endpoint, setting `block_mode` to `true`:

```sh
curl -X POST https://us.api.konghq.tech/bot-gline-manager/waap/$CONTROL_PLANE_ID/enabled \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "block_mode": true}'
```

To turn Bot Detector off entirely for the control plane, set `enabled` to `false`:

```sh
curl -X POST https://us.api.konghq.tech/bot-gline-manager/waap/$CONTROL_PLANE_ID/enabled \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```
{% endnavtab %}
{% navtab "UI" %}
Once enabled, a control plane's Bot Detector starts in monitoring mode. 
To switch modes, click **Enable blocking**.
To turn Bot Detector off entirely, from the **Actions** dropdown menu, select "Disable bot detector".
{% endnavtab %}
{% endnavtabs %}

Continue monitoring traffic to ensure traffic is flowing in the way you expect. 