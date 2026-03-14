# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  class RenderPrereqs < Liquid::Tag
    def render(context)
      @context = context
      @page = context.environments.first['page']

      return unless @page['prerequisites'].any?

      context.stack do
        context['prereqs'] = @page['prerequisites']
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/prereqs.md'))
      else
        File.read(File.expand_path('app/_includes/components/prereqs.html'))
      end
    end
  end
end

Liquid::Template.register_tag('prereqs', Jekyll::RenderPrereqs)
