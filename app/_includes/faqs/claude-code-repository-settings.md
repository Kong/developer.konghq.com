{% if include.section == "question" %}

Can a repository's settings point {{ site.claude_code }} at the gateway?
{% elsif include.section == "answer" %}

A repository's `.claude/settings.json` can't point {{ site.claude_code }} at the gateway on an interactive first run.
In an interactive session, when only the repository's `.claude/settings.json` sets the gateway address and token in `env`, a new {{ site.claude_code }} install asks for an Anthropic login method before it uses them.
{{ site.claude_code }} applies `env` values from that file only after the developer trusts the folder.
Values that {{ site.claude_code }} classifies as safe, such as model selection and timeouts, apply without that trust.
In `-p` mode, {{ site.claude_code }} applies the `env` values from that file at startup.
[`kong-harnesses setup`](/kong-harnesses/) writes the gateway settings to the developer's user settings, so {{ site.claude_code }} uses the gateway from the first interactive session.

{% endif %}
