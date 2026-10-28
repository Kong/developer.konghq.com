# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderAIPolicyPriorities < Liquid::Tag
    def render(context)
      page = context.environments.first['page']

      context.stack do
        context['rows'] = Drops::AIGateway::PolicyPriority.all
        ComponentTemplates.fetch('ai_policy_priorities', page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('ai_policy_priorities', Jekyll::RenderAIPolicyPriorities)
