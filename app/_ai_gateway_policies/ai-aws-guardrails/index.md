---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---


The AI AWS Guardrails Policy enforces introspection on both inbound requests and outbound responses handled by the AI Proxy plugin. It integrates with the AWS Bedrock Guardrails service to apply compliance and safety policies at the gateway level. This ensures all data exchanged between clients and upstream LLMs adheres to the configured security standards.