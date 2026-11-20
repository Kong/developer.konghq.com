{% if include.section == "question" %}

Can a repository's settings point {{ site.claude_code }} at the gateway?
{% elsif include.section == "answer" %}

Not on a first run.
A new {{ site.claude_code }} install asks for an Anthropic login method before it uses the `env` values in the repository's `.claude/settings.json`, and it applies most of those values only after the developer trusts the folder.
`kong-harnesses setup` writes the gateway settings to the developer's user settings, so {{ site.claude_code }} uses the gateway from the first session.

{% endif %}
