# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderKonnectMcpAgentInstructions < Liquid::Tag
    ELIGIBLE_PRODUCTS = %w[gateway ai-gateway event-gateway identity].freeze
    DATA_PLANE_PRODUCTS = %w[gateway ai-gateway event-gateway].freeze

    def render(context)
      @context = context
      @page = context.environments.first['page']

      return '' unless eligible?

      context.stack do
        context['agent_instructions_product'] = data_plane_product
        ComponentTemplates.fetch('konnect_mcp_agent_instructions', @page['output_format']).render(context)
      end
    end

    private

    def eligible?
      works_on = @page.fetch('works_on', [])
      products = @page.fetch('products', [])

      works_on.include?('konnect') && ELIGIBLE_PRODUCTS.include?(products.first)
    end

    def data_plane_product
      @page.fetch('products', []).find { |product| DATA_PLANE_PRODUCTS.include?(product) }
    end
  end
end

Liquid::Template.register_tag('konnect_mcp_agent_instructions', Jekyll::RenderKonnectMcpAgentInstructions)
