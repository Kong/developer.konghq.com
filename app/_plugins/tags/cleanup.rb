# frozen_string_literal: true

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
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/cleanup.md'))
      else
        File.read(File.expand_path('app/_includes/components/cleanup.html'))
      end
    end
  end
end

Liquid::Template.register_tag('cleanup', Jekyll::RenderCleanup)
