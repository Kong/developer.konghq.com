{% if include.section == "question" %}

How do I set up {{ site.claude_code }} for my developers?
{% elsif include.section == "answer" %}

Protect the AI Model with an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/), and create a [kong-harnesses](/kong-harnesses/) profile for the gateway with `kong-harnesses profile create --model {{ include.model }}`.
The command asks for the details of your identity provider and gateway, or takes them as flags.
The setup guide linked below shows these values.
{%- if include.provider == "bedrock" %}
The AI Model in this guide accepts the Anthropic format, so keep the default `anthropic` provider in the profile, even though the model runs on Bedrock.
Save the profile as a file with `kong-harnesses profile get <profile> -o json | jq .profile > <profile>.json`.
In that file, set `experimental_betas` to `false` in the `request_shape` block that `profile create` wrote, so {{ site.claude_code }} doesn't send the experimental beta fields that Bedrock rejects:

```json
{
  "clients": {
    "claude-code": {
      "request_shape": {
        "experimental_betas": false
      }
    }
  }
}
```
{:.no-copy-code}

Give developers the file or an HTTPS URL to it.
{%- else %}
Save the profile as a file with `kong-harnesses profile get <profile> -o json | jq .profile > <profile>.json`, and give developers the file or an HTTPS URL to it.
{%- endif %}
Each developer runs `kong-harnesses setup <profile-url> --client claude-code`, which signs them in and writes the gateway address and a credential helper to their own {{ site.claude_code }} settings.
For the steps with Okta, see [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).

{% endif %}
