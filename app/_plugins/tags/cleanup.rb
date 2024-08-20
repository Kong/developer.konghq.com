# frozen_string_literal: true

module Jekyll
  class RenderCleanup < Liquid::Tag
    def render(context)
      @context = context
      @page = context.environments.first['page']

      tools   = @page.fetch('tools', {})
      cleanup = @page.fetch('cleanup', {})

      cleanup_drop = Drops::Cleanup.new(cleanup:, tools:)

      if cleanup_drop.any?
        context.stack do
          context['cleanup'] = cleanup_drop
          Liquid::Template.parse(template).render(context)
        end
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/cleanup.html'))
    end
  end
end

Liquid::Template.register_tag('cleanup', Jekyll::RenderCleanup)
