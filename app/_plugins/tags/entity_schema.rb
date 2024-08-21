# frozen_string_literal: true

module Jekyll
  class RenderEntitySchema < Liquid::Tag
    def render(context)
      @context = context
      page = context.environments.first['page']
      site = context.registers[:site]

      schema = page['schema']

      if schema
        entity_schema_drop = Drops::EntitySchema.new(schema:, site:)

        context.stack do
          context['entity_schema'] = entity_schema_drop
          Liquid::Template.parse(template).render(context)
        end
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/entity_schema.html'))
    end
  end
end

Liquid::Template.register_tag('entity_schema', Jekyll::RenderEntitySchema)
