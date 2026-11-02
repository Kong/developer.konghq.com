# Known traps

Check these before concluding a policy "works" or "is broken". Re-verify against the current runtime, since fixes may have landed.

- A `200` alone is not proof the policy ran. Check the policy's own response or the data plane logs.
- Consumer and Consumer Group scopes apply only after the client authenticates.
- Some policies are inert at Model scope. Examples seen: JSON Threat Protection enforced correctly on an AI MCP Server but never fired on an AI Model (runtime 2.0.2-rc.3); `ip-restriction` was not enforced at Model scope because of a priority problem.
- Sandbox-related findings (Lua policies): consumer-scope policies could wedge data plane sync; `untrusted_lua = off` rejects the config; when several policies conflict, the highest ID wins.
- Plugin options tied to Gateway-only concepts (Service, Route, Upstream entity, ACL plugin, Consumer groups through ACL, Forward Proxy) are the likeliest to behave differently. Test them first, and treat failure as a finding.
- Model-scoped policy ordering: "plugin cloning" is a misleading label. Verify ordering live, do not infer it from the label.
- Tool-level ACLs on AI MCP Servers were broken in both directions on 2.0.1-rc.1 (per-tool ACLs returned a universal 403, default tool ACLs were never enforced).
