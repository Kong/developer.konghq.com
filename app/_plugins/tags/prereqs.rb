# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  class RenderPrereqs < Liquid::Tag
    def render(context)
      @context = context
      @page = context.environments.first['page']

      return unless @page['prerequisites'].any?

      # Set prereqs on both the context stack and the environment.
      # The `liquify` filter renders templates with only the environment hash,
      # not the full context, so nested tags (e.g. navtabs inside inline prereqs)
      # would not see prereqs if it were only on the stack.
      environment = context.environments.first
      context.stack do
        context['prereqs'] = @page['prerequisites']
        environment['prereqs'] = @page['prerequisites']
        result = Liquid::Template.parse(template, { line_numbers: true }).render(context)
        environment['prereqs'] = nil
        result
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
