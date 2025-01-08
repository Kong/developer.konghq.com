# frozen_string_literal: true

module Jekyll
  module RenderPlugins
    class Protocols < Liquid::Tag
      def render(context)
        @context = context
        @page = context.environments.first['page']
        site = context.registers[:site]

        release = @page['release']
        table = site.data.dig('plugins', 'tables', 'protocols')

        context.stack do
          context['columns'] = table['columns']
          context['rows'] = Drops::Plugins::Protocol.all(release:)
          Liquid::Template.parse(template).render(context)
        end
      end

      private

      def template
        @template ||= File.read(File.expand_path('app/_includes/plugins/table.html'))
      end
    end
  end
end

Liquid::Template.register_tag('plugin_protocols', Jekyll::RenderPlugins::Protocols)
