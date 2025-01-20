# frozen_string_literal: true

module Jekyll
  module RenderPlugins
    class ReferenceableFields < Liquid::Tag # rubocop:disable Style/Documentation
      def render(context)
        @context = context
        @page = context.environments.first['page']
        site = context.registers[:site]

        release = @page['release']
        table = site.data.dig('plugins', 'tables', 'referenceable_fields')

        context.stack do
          context['columns'] = table['columns']
          context['rows'] = Drops::Plugins::ReferenceableFields.all(release:).select(&:any?)
          Liquid::Template.parse(template).render(context)
        end
      end

      private

      def template
        @template ||= File.read(File.expand_path('app/_includes/plugins/referenceable_fields.html'))
      end
    end
  end
end

Liquid::Template.register_tag('referenceable_fields', Jekyll::RenderPlugins::ReferenceableFields)
