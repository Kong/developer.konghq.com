# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderKongConf < Liquid::Tag # rubocop:disable Style/Documentation
    def render(context)
      @page = context.environments.first['page']
      product = @page['products']&.first || 'gateway'

      context.stack do
        context['config'] = Drops::KongConf.new(product)
        ComponentTemplates.fetch('kong_conf', @page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('kong_conf', Jekyll::RenderKongConf)
