---
title: Pin a {{ site.claude_code }} fleet to a tested version range
content_type: how_to
permalink: /kong-harnesses/pin-a-claude-code-fleet/
breadcrumbs:
  - /kong-harnesses/

description: Hold managed {{ site.claude_code }} computers to the versions that you tested through {{ site.ai_gateway }}, so an automatic update never moves the fleet to an untested release.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

automated_tests: false

min_version:
  ai-gateway: '2.4'

tags:
  - ai
  - anthropic

related_resources:
  - text: Roll out {{ site.claude_code }} through MDM
    url: /kong-harnesses/roll-out-claude-code-through-mdm/
  - text: Move a {{ site.claude_code }} fleet to a new model
    url: /kong-harnesses/move-a-claude-code-fleet-to-a-new-model/
  - text: "{{ site.claude_code }} fleet build options"
    url: /kong-harnesses/fleet-build-options/
  - text: Troubleshoot a {{ site.claude_code }} fleet
    url: /kong-harnesses/troubleshooting/claude-code-fleet/
  - text: Remove a {{ site.claude_code }} fleet build
    url: /kong-harnesses/remove-a-claude-code-fleet-build/

prereqs:
  inline:
    - title: A fleet build
      content: |
        Roll out {{ site.claude_code }} with `kong-harnesses fleet build`, as described in [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/).
        Keep the record file of that build (`kong-harnesses-fleet-BUILD_ID.json`) and the policy that your computers get now.
    - title: Okta
      icon_url: /assets/icons/okta.svg
      include_content: prereqs/auth/oidc/okta-kong-harnesses
    - title: Tested {{ site.claude_code }} releases
      content: |
        Test the releases that you want to allow through {{ site.ai_gateway }}, on at least one computer.

tldr:
  q: How do I hold a managed {{ site.claude_code }} fleet to tested versions?
  a: |
    Run `kong-harnesses fleet build --record RECORD_FILE --claude-code-minimum OLDEST_VERSION --claude-code-maximum NEWEST_VERSION`.
    Test the new build on one computer in each policy group, then deploy it to the rest.
---

{{ site.claude_code }} updates itself, so a release that you haven't tested can reach every managed computer.
A [kong-harnesses](/kong-harnesses/) fleet build can hold the computers to a version range.
{{ site.claude_code }} refuses to start outside the range, and its updates stay inside it.

## Choose the version range

Choose `OLDEST_VERSION` and `NEWEST_VERSION` from the {{ site.claude_code }} releases that you tested through {{ site.ai_gateway }}.
Use the three-number form that `claude --version` prints, for example `2.1.285`.

{% table %}
columns:
  - title: Bound
    key: bound
  - title: Rule
    key: rule
  - title: Why
    key: why
rows:
  - bound: "`OLDEST_VERSION`"
    rule: "`2.1.163` or later. Use `2.1.285` or later."
    why: "A release earlier than `2.1.163` ignores version bounds. A release earlier than `2.1.285` doesn't keep every session on the gateway."
  - bound: "`NEWEST_VERSION`"
    rule: "`2.1.285` or later."
    why: "{{ site.claude_code }} can update to any release inside the range, so test the releases between the bounds too."
{% endtable %}

To hold the fleet to one release, use the same version for both bounds.
For how each install method updates inside the range, and the extra steps for Homebrew and Claude Desktop, see [How version bounds behave](/kong-harnesses/fleet-build-options/#how-version-bounds-behave).

{:.warning}
> **Check the current range before you install a release:** {{ site.claude_code }} refuses to start when its release is outside the range that applies.
> If the range in the current policy does not permit a release in the new range, install that release on each computer in the same maintenance window as the new build.

## Rebuild the managed settings

{% include kong-harnesses/fleet-rebuild.md change="--claude-code-minimum OLDEST_VERSION --claude-code-maximum NEWEST_VERSION" %}

If `fleet build` refuses the version range, see [Version range checks](/kong-harnesses/fleet-build-options/#version-range-checks).

## Test the build on one computer

Test the build on one managed computer in each policy group:

1. Run `claude --version` to note the current release, so you can put it back if a test fails.
   If that release is outside the new range, install a release from `OLDEST_VERSION` to `NEWEST_VERSION`.
1. Deploy only the build in `NEW_FOLDER` to the test computer, as described in [Deploy to managed computers](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
   For an MDM build, assign the new MDM policy only to the test computer.
1. Run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` and confirm the new build ID.
1. Start {{ site.claude_code }} with `claude`, send a prompt, and confirm that it replies.

If a test fails, put the test computer back on the earlier build and see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).

## Deploy the build to the other computers

{% include kong-harnesses/fleet-deploy-rest.md pin=true %}

## Validate

On a managed computer after you deploy the build, check the {{ site.claude_code }} release and run [`kong-harnesses doctor`](/kong-harnesses/doctor/).

1. Check the release:

   {% validation custom-command %}
   command: claude --version
   expected:
     return_code: 0
   render_output: false
   indent: 3
   {% endvalidation %}

   The command prints a release from `OLDEST_VERSION` to `NEWEST_VERSION`.
1. Run `doctor`:

   {% validation custom-command %}
   command: kong-harnesses doctor --profile PROFILE_NAME --client claude-code
   expected:
     return_code: 0
   render_output: false
   indent: 3
   {% endvalidation %}

   The command exits with code `0`, and its output says that your organization's managed settings configure {{ site.claude_code }}, with the build ID of the build that you deployed.
