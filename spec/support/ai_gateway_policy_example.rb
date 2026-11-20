# frozen_string_literal: true

def ai_gateway_policy_plugin(scopes: %w[global ai-model ai-agent ai-mcp-server])
  double(
    'ai-gateway policy',
    product: 'ai-gateway',
    slug: 'ai-sanitizer',
    scopes:,
    unreleased?: false,
    min_release: nil
  )
end

def ai_gateway_policy_config_example(file:, scopes: %w[global ai-model ai-agent ai-mcp-server])
  Jekyll::Drops::PolicyConfigExample::AIGateway.new(
    file:,
    plugin: ai_gateway_policy_plugin(scopes:)
  )
end
