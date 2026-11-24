After every test passes, deploy the new build to the other computers in each policy group:

1. Deploy the same package or files, and for an MDM build the same MDM policy, to the other computers in the group.
   Use the steps in [Deploy to managed computers](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
{% if include.pin %}
   Install a release from `OLDEST_VERSION` to `NEWEST_VERSION` on each computer whose release is outside that range, in the same maintenance window as the deploy to that computer.
{% endif %}
1. Keep the new record file with the policy, and keep the command that made this build.
   For the next rebuild, the new record file is `RECORD_FILE` and the policy that the computers then get is `POLICY_FILE`.
1. When your MDM or install tool confirms the new build on every computer, ask developers to finish their current task and restart {{ site.claude_code }}.
   A running session keeps its release and model until the developer restarts it.
