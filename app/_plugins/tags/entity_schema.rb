# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderEntitySchema < Liquid::Tag
    def render(context)
      @context = context
      @page = context.environments.first['page']
      site = context.registers[:site]
      release = @page['release']
      schema = @page['schema']

      return unless schema

      entity_schema_drop = Drops::EntitySchema.new(schema:, site:, release:)

      context.stack do
        context['entity_schema'] = entity_schema_drop
        ComponentTemplates.fetch('entity_schema', @page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('entity_schema', Jekyll::RenderEntitySchema)
