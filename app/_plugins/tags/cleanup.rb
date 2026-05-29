# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderCleanup < Liquid::Tag
    def render(context)
      @context = context
      @page = context.environments.first['page']

      tools   = @page.fetch('tools', {})
      cleanup = @page.fetch('cleanup', {})

      cleanup_drop = Drops::Cleanup.new(cleanup:, tools:)

      return unless cleanup_drop.any?

      context.stack do
        context['cleanup'] = cleanup_drop
        ComponentTemplates.fetch('cleanup', @page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('cleanup', Jekyll::RenderCleanup)
