# frozen_string_literal: true

module Jekyll
  module RenderPlugins
    class Scopes < Liquid::Tag
      def render(context)
        @context = context
        @page = context.environments.first['page']
        site = context.registers[:site]

        release = @page['release']
        table = site.data.dig('plugins', 'tables', 'scopes')

        context.stack do
          context['columns'] = table['columns']
          context['rows'] = Drops::Plugins::Scope.all(release:)
          Liquid::Template.parse(template).render(context)
        end
      end

      private

      def template
        @template ||= File.read(File.expand_path('app/_includes/plugins/scopes.html'))
      end
    end
  end
end

Liquid::Template.register_tag('plugin_scopes', Jekyll::RenderPlugins::Scopes)
