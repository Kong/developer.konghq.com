CEL-based ACLs control access with [CEL](https://cel.dev/) boolean expressions instead of a static list of names.
Use them when access depends on Consumer attributes or request context, not only on fixed names.
To use them, set `allow_when` or `deny_when` on the {{include.scope}}[`access.acls`]({{include.anchor}}) object.
Each field is an array of expressions, 1 to 1024 characters each.
The data plane evaluates the expressions on each request, against the authenticated AI Consumer and the request. They use the same field vocabulary as [plugin conditions](/gateway/plugins/conditions/).
{% if include.allow_and_deny_together -%}
`allow_when` and `deny_when` are mutually exclusive with `allow` and `deny`.
For {{include.entity}}s, you can set `allow` and `deny` together, as described in [ACL evaluation logic](#acl-evaluation-logic).
{%- else -%}
Configure exactly one of `allow`, `deny`, `allow_when`, or `deny_when` per `access.acls` object.
{%- endif %}

The following example allows requests from AI Consumers in the `internal-teams` AI Consumer Group, and from the AI Consumer `alice`:

```yaml
access:
  acls:
    allow_when:
      - 'consumer_group.names != null && "internal-teams" in consumer_group.names'
      - 'consumer.username == "alice"'
```

{{site.konnect_short_name}} compiles and type-checks each expression when you create or update the {{include.entity}}.
{{site.konnect_short_name}} rejects an entry that doesn't compile or doesn't evaluate to a boolean with HTTP 400.
The error names the offending entry, for example `access.acls.allow_when[0]`.

At runtime, entries are evaluated in order with OR semantics.
When you set `allow_when`, the request is allowed if any entry evaluates to true.
If an entry fails to evaluate, the request is denied with HTTP 403.
When you set `deny_when`, the request is denied if any entry evaluates to true.
If an entry fails to evaluate, the request fails closed with HTTP 500.

When you set `allow_when` or `deny_when`, {{site.ai_gateway}} ignores `include_consumer_groups`.
It also doesn't send the `X-Consumer-Groups` and `X-Authenticated-Groups` headers upstream.

CEL-based ACLs need {{site.base_gateway}} 3.16 or later data planes.
Data planes on earlier versions report the skipped configuration in their compatibility status.
