{% if include.section == "question" %}

Can a repository's settings point {{ site.claude_code }} at the gateway?
{% elsif include.section == "answer" %}

Not on an interactive first run.
In an interactive session, when only the repository's `.claude/settings.json` sets the gateway address and token in `env`, a new {{ site.claude_code }} install asks for an Anthropic login method before it uses them.
{{ site.claude_code }} also applies `env` values from that file only after the developer trusts the folder, except the values that it classifies as safe, such as model selection and timeouts.
In `-p` mode, {{ site.claude_code }} applies those values at startup.
`kong-harnesses setup` writes the gateway settings to the developer's user settings, so {{ site.claude_code }} uses the gateway from the first interactive session.

{% endif %}
