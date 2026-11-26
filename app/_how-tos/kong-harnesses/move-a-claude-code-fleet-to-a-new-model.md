---
title: Move a {{ site.claude_code }} fleet to a new model
content_type: how_to
permalink: /kong-harnesses/move-a-claude-code-fleet-to-a-new-model/
breadcrumbs:
  - /kong-harnesses/

description: Move managed {{ site.claude_code }} computers to a new Claude model version through {{ site.ai_gateway }} without interrupting active sessions.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses
  - kongctl

automated_tests: false

min_version:
  ai-gateway: '2.4'

entities:
  - ai-model

tags:
  - ai
  - anthropic

related_resources:
  - text: Pin a {{ site.claude_code }} fleet to a tested version range
    url: /kong-harnesses/pin-a-claude-code-fleet/
  - text: "{{ site.claude_code }} model configuration"
    url: https://code.claude.com/docs/en/model-config

prereqs:
  inline:
    - title: A fleet build
      content: |
        Roll out {{ site.claude_code }} with `kong-harnesses fleet build`.
        Keep the record file of that build (`kong-harnesses-fleet-BUILD_ID.json`) and the policy that your computers get now.
    - title: Okta
      icon_url: /assets/icons/okta.svg
      include_content: prereqs/auth/oidc/okta-kong-harnesses
    - title: The earlier AI Model
      content: |
        You need the [AI Model](/ai-gateway/entities/ai-model/) that your fleet uses now.
        The new AI Model reuses its AI Model Provider and AI Auth Strategy.

tldr:
  q: How do I move a managed {{ site.claude_code }} fleet to a new model?
  a: |
    Add the new model as a separate AI Model with the same access as the earlier one.
    Run `kong-harnesses fleet build --record RECORD_FILE --model 'FAMILY=NEW_MODEL_ID'`, test the build on one computer, and deploy it to the rest.
---

When Anthropic releases a new Claude model, your managed {{ site.claude_code }} computers keep using the earlier model until you move them.
You add the new model to {{ site.ai_gateway }}, and then rebuild the fleet with the new model name.
Developers switch the next time they restart {{ site.claude_code }}, so active sessions keep working.

## Create the new AI Model

Create the new model as a separate [AI Model](/ai-gateway/entities/ai-model/) that has the same settings as the earlier one.
Change `claude-sonnet-5-5`, `anthropic`, and `okta-oidc` to the new model name, the AI Model Provider, and the AI Auth Strategy of your earlier AI Model:

<!-- TODO: Test this entity on a {{site.konnect_short_name}} AI Gateway before publishing. -->

{% entity_examples %}
ai_gateway_models:
  - ref: new-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: claude-sonnet-5-5
    name: claude-sonnet-5-5
    type: model
    capabilities:
      - generate
    formats:
      - type: anthropic
    targets:
      - name: claude-sonnet-5-5
        provider: anthropic
        config:
          type: anthropic
    access:
      auth_strategies:
        - okta-oidc
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claude-sonnet-5-5
{% endentity_examples %}

Match the earlier AI Model in three more ways:

* Copy its other `access` settings, such as `access.acls`, and attach the same [AI Policies](/ai-gateway/entities/ai-model/#attach-ai-policies), such as guardrails and rate limits.
* Copy `config.route.paths` and the rest of `config`, such as `response_streaming`, from the earlier AI Model.
  The fleet sends requests to the path of the earlier AI Model, such as `/claude-code-sso` in the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/), so a new AI Model on another path gets none of them.
* Give the new AI Model its own value in the routing rule (`config.route.model`), so each model gets its own requests.

{:.warning}
> **Keep the earlier AI Model active:** Do not remove it until every policy group has the new build and no client sends requests to it.
> A {{ site.claude_code }} session fails when {{ site.ai_gateway }} does not serve its model.

## Rebuild the managed settings

Rebuild with `--model 'FAMILY=NEW_MODEL_ID'`.
`FAMILY` is the {{ site.claude_code }} model family that you move: `opus`, `sonnet`, `haiku`, or `fable`.
`NEW_MODEL_ID` is the value that the routing rule (`config.route.model`) of the new AI Model accepts, one of its `values`.
In the example, the value is the same as the AI Model name, but the two can differ.
To move more than one family, repeat the option for each family.
If the earlier build set `--model` for a family that you don't name, `fleet build` refuses until you pass that `--model` again.
A family that had no earlier `--model` gets the model that the profile has now, which can differ from the earlier one.

{% include kong-harnesses/fleet-rebuild.md change="--model 'FAMILY=NEW_MODEL_ID'" %}

If the new model needs a newer {{ site.claude_code }} release, [pin a version range](/kong-harnesses/pin-a-claude-code-fleet/) in the same rebuild.
Find the earliest release in [Model configuration](https://code.claude.com/docs/en/model-config).

## Test the build on one computer

Test the build on one managed computer in each policy group:

1. Start a session with `claude -n TEST_SESSION`, run `/model FAMILY`, and run `/status` to confirm that it shows the earlier model.
   Send a prompt, and leave the session open.
1. In another terminal, deploy only the build in `NEW_FOLDER` to the test computer.
   For an MDM build, assign the new MDM policy only to the test computer.
1. Run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` and confirm the new build ID.
1. Send another prompt in the open session to confirm that {{ site.claude_code }} replies.
   Then exit, resume with `claude --resume TEST_SESSION`, and run `/status` to confirm that the session no longer uses the earlier model.
1. Start a new session with `claude`, run `/model FAMILY`, and run `/status` to confirm that it shows `NEW_MODEL_ID`.
   Send a prompt, and confirm in the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) that the new model served the request.

If a test fails, put the test computer back on the earlier build.

## Deploy the build to the other computers

{% include kong-harnesses/fleet-deploy-rest.md %}

Developers get the new model when they restart {{ site.claude_code }}.
If `/status` still shows the earlier model, ask them to run `/model FAMILY`.

## Remove the earlier AI Model

When every policy group has the new build, check the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger), filtered by **Model**.
After the Events debugger stops showing new requests for the earlier model, remove the earlier AI Model from {{ site.ai_gateway }}.

## Validate

On a managed computer, run [`kong-harnesses doctor`](/kong-harnesses/doctor/):

{% validation custom-command %}
command: kong-harnesses doctor --profile PROFILE_NAME --client claude-code
expected:
  return_code: 0
render_output: false
{% endvalidation %}

The command exits with code `0`, and its output names the build ID of the build that you deployed.
Then start {{ site.claude_code }} and run `/status` to confirm that it shows `NEW_MODEL_ID`.
