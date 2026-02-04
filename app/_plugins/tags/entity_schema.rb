# frozen_string_literal: true

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
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= if @page['output_format'] == 'markdown'
                      File.read(File.expand_path('app/_includes/components/entity_schema.md'))
                    else
                      File.read(File.expand_path('app/_includes/components/entity_schema.html'))
                    end
    end
  end
end

Liquid::Template.register_tag('entity_schema', Jekyll::RenderEntitySchema)
