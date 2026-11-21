CEL-based ACLs control access with [CEL](https://cel.dev/) boolean expressions instead of a static list of names.
Use them when access depends on Consumer attributes or request context, not only on fixed names.
To use them, set `allow_when` or `deny_when` on the {{include.scope}}[`access.acls`]({{include.anchor}}) object.
Each field is an array of expressions, 1 to 1024 characters each.
The data plane evaluates the expressions on each request against the authenticated caller and the request itself.
The caller is the AI Consumer and, when the AI Auth Strategy maps one, the {{site.identity}} [Principal](/identity/principals/).
Expressions can also read `actors`, the separate entities acting on that Principal's behalf.
The expressions use the same field vocabulary as [plugin conditions](/gateway/plugins/conditions/).
See [AI Policy conditions](/ai-gateway/conditions/#context-fields) for the full field list.
Configure exactly one of `allow`, `deny`, `allow_when`, or `deny_when` per `access.acls` object.

The following example allows requests from AI Consumers in the `internal-teams` AI Consumer Group, and from the AI Consumer `alice`:

```yaml
access:
  acls:
    allow_when:
      - 'consumer_group.names != null && "internal-teams" in consumer_group.names'
      - 'consumer.username == "alice"'
```

<!--vale off-->
{% comment %}
TODO (actors, AI Gateway 2.4): confirm against the RC whether these ACL
expressions accept list indexing, exists(), size(), and default().

AI Policy conditions reject all four (see the "Differences from Kong Gateway
plugin conditions" section of app/ai-gateway/conditions.md), but the merged ACL
schema tests in Kong/kong-ee#24739 accept
`actors.exists(a, a.metadata.kind == "agent")` and
`default(actors[0].metadata.tier == 3, false)`.

This matters because the two-party rule that `actors` exists to express, allow a
tool only when agent Y acts for a user in group Z, needs exists() or indexing to
reach a specific actor. If these ACLs accept it, add that worked example here
and link to it from conditions.md. If they don't, say so on both pages, since
the ERD and both PRDs lead with an exists() example.

Also confirm: actors[i].groups is an empty list rather than null when an actor
has no groups (Kong/kong-ee#24739, build_actors), so exists() and size() on it
need no null guard, unlike `actors` itself. Worth documenting if these
functions turn out to be available.
{% endcomment %}
<!--vale on-->

{{site.konnect_short_name}} compiles and type-checks each expression when you create or update the {{include.entity}}.
{{site.konnect_short_name}} rejects an entry that doesn't compile or doesn't evaluate to a boolean with HTTP 400.
The error message describes the problem, for example `expression must evaluate to a boolean`. It doesn't identify which array entry caused it.

At runtime, entries are evaluated in order with OR semantics.
Failures to evaluate create the following responses:

* **If an entry fails to evaluate and no other entry evaluates to true:**  The request is denied with HTTP 403.
* **If an earlier entry failed but the entry evaluates to true:** The request is allowed, unless you set `deny_when`.
* **If an entry fails to evaluate before an entry that evaluates to true:** The request fails closed with HTTP 500.
* **If an entry that evaluates to true comes first:** The request is denied with HTTP 403 and later entries aren't evaluated.

When you set `allow_when` or `deny_when`, {{site.ai_gateway}} ignores `include_consumer_groups`.
It also doesn't send the `X-Consumer-Groups` and `X-Authenticated-Groups` headers upstream.

CEL-based ACLs need {{site.base_gateway}} 3.16 or later data planes.
Data planes on earlier versions report the skipped configuration in their compatibility status.
