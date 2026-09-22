{% mermaid %}
flowchart TD
  start["LLM traffic through {{site.base_gateway}}"]
  start --> q1{"What is the client?"}
  q1 -->|"Chat app, assistant, RAG"| A["Straiker<br/>webhook plugin"]
  q1 -->|"Claude Code or other Anthropic<br/>Messages coding agent"| q2{"Must a tool call be<br/>stopped before it runs?"}
  q2 -->|"No, interactive developers"| B["Straiker Coding Agent Streaming"]
  q2 -->|"Yes, CI or unattended agents"| C["Straiker Coding Agent Buffered"]
  click A "/plugins/straiker/"
  click B "/plugins/straiker-coding-agent-streaming/"
  click C "/plugins/straiker-coding-agent-buffered/"
{% endmermaid %}
